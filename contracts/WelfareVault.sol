// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ParticipantRegistry} from "./ParticipantRegistry.sol";

/**
 * @title WelfareVault
 * @notice Purpose-bound, programmable welfare disbursement. A department (SCHEME_ADMIN) creates a scheme
 *         locked to ONE spending category, funds it with simulated e-rupee, and allocates entitlements to
 *         registered beneficiaries. A beneficiary can only spend the entitlement at registered, un-suspended
 *         merchants approved for that category, inside the scheme window, below the per-transaction cap.
 *         Unspent entitlements are returned to the department treasury after expiry by anyone.
 *
 *         Accounting identity (checked by isSolvent()):
 *             token.balanceOf(vault) >= totalLiabilities
 *         where totalLiabilities = sum over schemes of (pool + outstanding).
 */
contract WelfareVault is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant SCHEME_ADMIN_ROLE = keccak256("SCHEME_ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    uint256 public constant MAX_BATCH = 100;

    struct Scheme {
        string name;
        address owner;
        uint8 category;
        uint64 startTime;
        uint64 expiry;
        uint256 perTxnCap; // 0 = no cap
        bool paused;
        uint256 pool; // funded, not yet allocated
        uint256 outstanding; // allocated to beneficiaries, not yet spent or reclaimed
        uint256 totalFunded;
        uint256 totalSpent;
        uint256 totalReclaimed;
    }

    IERC20 public immutable token;
    ParticipantRegistry public immutable registry;

    uint256 public schemeCount;
    uint256 public totalLiabilities;
    mapping(uint256 => Scheme) private _schemes;
    mapping(uint256 => mapping(address => uint256)) public entitlementOf;

    event SchemeCreated(
        uint256 indexed schemeId, address indexed owner, string name, uint8 category, uint64 startTime, uint64 expiry, uint256 perTxnCap
    );
    event SchemeFunded(uint256 indexed schemeId, address indexed from, uint256 amount);
    event Allocated(uint256 indexed schemeId, address indexed beneficiary, uint256 amount);
    event AllocationRevoked(uint256 indexed schemeId, address indexed beneficiary, uint256 amount);
    event Spent(
        uint256 indexed schemeId, address indexed beneficiary, address indexed merchant, uint256 amount, uint8 category, bytes32 invoiceRef
    );
    event Reclaimed(uint256 indexed schemeId, address indexed beneficiary, address indexed caller, uint256 amount);
    event PoolWithdrawn(uint256 indexed schemeId, uint256 amount);
    event SchemePausedChanged(uint256 indexed schemeId, bool paused, address indexed by);

    error InvalidScheme();
    error NotSchemeOwner();
    error InvalidName();
    error InvalidCategory();
    error InvalidWindow();
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientPool(uint256 available, uint256 requested);
    error BeneficiaryNotActive(address beneficiary);
    error MerchantNotEligible(address merchant, uint8 category);
    error SchemeIsPaused();
    error SchemeNotStarted();
    error SchemeExpired();
    error SchemeNotExpired();
    error ExceedsPerTxnCap(uint256 cap, uint256 requested);
    error InsufficientEntitlement(uint256 available, uint256 requested);
    error ArrayLengthMismatch();
    error BatchTooLarge();
    error NothingToReclaim();

    constructor(IERC20 token_, ParticipantRegistry registry_, address admin, address schemeAdmin, address compliance) {
        if (
            address(token_) == address(0) || address(registry_) == address(0) || admin == address(0)
                || schemeAdmin == address(0) || compliance == address(0)
        ) revert ZeroAddress();
        token = token_;
        registry = registry_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SCHEME_ADMIN_ROLE, schemeAdmin);
        _grantRole(COMPLIANCE_ROLE, compliance);
    }

    modifier onlySchemeOwner(uint256 schemeId) {
        Scheme storage s = _schemes[schemeId];
        if (s.owner == address(0)) revert InvalidScheme();
        if (s.owner != msg.sender) revert NotSchemeOwner();
        _;
    }

    // ------------------------------------------------------------ scheme set-up
    function createScheme(string calldata name, uint8 category, uint64 startTime, uint64 expiry, uint256 perTxnCap)
        external
        onlyRole(SCHEME_ADMIN_ROLE)
        returns (uint256 schemeId)
    {
        uint256 n = bytes(name).length;
        if (n == 0 || n > 64) revert InvalidName();
        if (category > registry.MAX_CATEGORY()) revert InvalidCategory();
        if (startTime == 0) startTime = uint64(block.timestamp);
        if (expiry <= startTime || expiry <= block.timestamp) revert InvalidWindow();

        schemeId = ++schemeCount;
        Scheme storage s = _schemes[schemeId];
        s.name = name;
        s.owner = msg.sender;
        s.category = category;
        s.startTime = startTime;
        s.expiry = expiry;
        s.perTxnCap = perTxnCap;
        emit SchemeCreated(schemeId, msg.sender, name, category, startTime, expiry, perTxnCap);
    }

    function fundScheme(uint256 schemeId, uint256 amount) external onlySchemeOwner(schemeId) nonReentrant {
        if (amount == 0) revert ZeroAmount();
        Scheme storage s = _schemes[schemeId];
        s.pool += amount;
        s.totalFunded += amount;
        totalLiabilities += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit SchemeFunded(schemeId, msg.sender, amount);
    }

    function allocate(uint256 schemeId, address beneficiary, uint256 amount) external onlySchemeOwner(schemeId) {
        _allocate(schemeId, beneficiary, amount);
    }

    function allocateBatch(uint256 schemeId, address[] calldata beneficiaries, uint256[] calldata amounts)
        external
        onlySchemeOwner(schemeId)
    {
        if (beneficiaries.length != amounts.length) revert ArrayLengthMismatch();
        if (beneficiaries.length > MAX_BATCH) revert BatchTooLarge();
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _allocate(schemeId, beneficiaries[i], amounts[i]);
        }
    }

    function _allocate(uint256 schemeId, address beneficiary, uint256 amount) internal {
        Scheme storage s = _schemes[schemeId];
        if (amount == 0) revert ZeroAmount();
        if (block.timestamp >= s.expiry) revert SchemeExpired();
        if (!registry.isBeneficiaryActive(beneficiary)) revert BeneficiaryNotActive(beneficiary);
        if (s.pool < amount) revert InsufficientPool(s.pool, amount);
        s.pool -= amount;
        s.outstanding += amount;
        entitlementOf[schemeId][beneficiary] += amount;
        emit Allocated(schemeId, beneficiary, amount);
    }

    /// @notice Take back an entitlement (e.g. beneficiary found ineligible); funds return to the scheme pool.
    function revokeAllocation(uint256 schemeId, address beneficiary) external onlySchemeOwner(schemeId) {
        uint256 amount = entitlementOf[schemeId][beneficiary];
        if (amount == 0) revert NothingToReclaim();
        Scheme storage s = _schemes[schemeId];
        entitlementOf[schemeId][beneficiary] = 0;
        s.outstanding -= amount;
        s.pool += amount;
        emit AllocationRevoked(schemeId, beneficiary, amount);
    }

    /// @notice Return un-allocated funds from the pool to the owner's treasury.
    function withdrawPool(uint256 schemeId, uint256 amount) external onlySchemeOwner(schemeId) nonReentrant {
        if (amount == 0) revert ZeroAmount();
        Scheme storage s = _schemes[schemeId];
        if (s.pool < amount) revert InsufficientPool(s.pool, amount);
        s.pool -= amount;
        totalLiabilities -= amount;
        token.safeTransfer(s.owner, amount);
        emit PoolWithdrawn(schemeId, amount);
    }

    // ----------------------------------------------------------------- spending
    /// @notice The beneficiary (msg.sender) pays `merchant` from the scheme entitlement.
    /// @param invoiceRef hash of the off-chain invoice / bill, stored in the event for audit.
    function spend(uint256 schemeId, address merchant, uint256 amount, bytes32 invoiceRef) external nonReentrant {
        Scheme storage s = _schemes[schemeId];
        if (s.owner == address(0)) revert InvalidScheme();
        if (s.paused) revert SchemeIsPaused();
        if (block.timestamp < s.startTime) revert SchemeNotStarted();
        if (block.timestamp >= s.expiry) revert SchemeExpired();
        if (amount == 0) revert ZeroAmount();
        if (!registry.isBeneficiaryActive(msg.sender)) revert BeneficiaryNotActive(msg.sender);
        if (!registry.isMerchantEligible(merchant, s.category)) revert MerchantNotEligible(merchant, s.category);
        if (s.perTxnCap != 0 && amount > s.perTxnCap) revert ExceedsPerTxnCap(s.perTxnCap, amount);
        uint256 available = entitlementOf[schemeId][msg.sender];
        if (amount > available) revert InsufficientEntitlement(available, amount);

        // effects
        entitlementOf[schemeId][msg.sender] = available - amount;
        s.outstanding -= amount;
        s.totalSpent += amount;
        totalLiabilities -= amount;

        // interaction
        token.safeTransfer(merchant, amount);
        emit Spent(schemeId, msg.sender, merchant, amount, s.category, invoiceRef);
    }

    /// @notice After expiry anyone may return a beneficiary's unspent entitlement to the department treasury.
    function reclaimExpired(uint256 schemeId, address beneficiary) external nonReentrant {
        Scheme storage s = _schemes[schemeId];
        if (s.owner == address(0)) revert InvalidScheme();
        if (block.timestamp < s.expiry) revert SchemeNotExpired();
        uint256 amount = entitlementOf[schemeId][beneficiary];
        if (amount == 0) revert NothingToReclaim();

        entitlementOf[schemeId][beneficiary] = 0;
        s.outstanding -= amount;
        s.totalReclaimed += amount;
        totalLiabilities -= amount;
        token.safeTransfer(s.owner, amount);
        emit Reclaimed(schemeId, beneficiary, msg.sender, amount);
    }

    // --------------------------------------------------------------- compliance
    function setSchemePaused(uint256 schemeId, bool paused) external onlyRole(COMPLIANCE_ROLE) {
        Scheme storage s = _schemes[schemeId];
        if (s.owner == address(0)) revert InvalidScheme();
        s.paused = paused;
        emit SchemePausedChanged(schemeId, paused, msg.sender);
    }

    // -------------------------------------------------------------------- views
    function getScheme(uint256 schemeId) external view returns (Scheme memory) {
        if (_schemes[schemeId].owner == address(0)) revert InvalidScheme();
        return _schemes[schemeId];
    }

    function isSolvent() external view returns (bool) {
        return token.balanceOf(address(this)) >= totalLiabilities;
    }
}
