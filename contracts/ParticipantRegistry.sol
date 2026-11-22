// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ParticipantRegistry
 * @notice Permissioned on-chain registry of (a) merchants approved to accept welfare tokens, with the
 *         spending categories each may serve, and (b) beneficiaries, identified ONLY by a salted hash of
 *         an off-chain identity reference (never an Aadhaar number or any raw personal data).
 *
 *         Category IDs (0..15) are a bitmask position. Reference mapping used by the PoC front end:
 *         0 FOOD_GRAIN, 1 FERTILISER, 2 HEALTHCARE, 3 EDUCATION.
 */
contract ParticipantRegistry is AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    uint8 public constant MAX_CATEGORY = 15;

    struct Merchant {
        bool approved;
        bool suspended;
        uint16 categoryMask;
        bytes32 licenceHash; // hash of the trade licence / GSTIN reference held off-chain
        string name;
    }

    struct Beneficiary {
        bool registered;
        bool frozen;
        bytes32 idHash;
    }

    mapping(address => Merchant) private _merchants;
    mapping(address => Beneficiary) private _beneficiaries;
    mapping(bytes32 => address) public walletOfIdHash;
    address[] private _merchantList;
    address[] private _beneficiaryList;

    event MerchantRegistered(address indexed merchant, string name, uint16 categoryMask, bytes32 licenceHash);
    event MerchantCategoriesUpdated(address indexed merchant, uint16 categoryMask);
    event MerchantSuspensionChanged(address indexed merchant, bool suspended);
    event BeneficiaryRegistered(address indexed wallet, bytes32 indexed idHash);
    event BeneficiaryFreezeChanged(address indexed wallet, bool frozen);

    error ZeroAddress();
    error InvalidName();
    error InvalidCategoryMask();
    error InvalidHash();
    error AlreadyRegistered(address who);
    error DuplicateIdentity(bytes32 idHash);
    error NotRegistered(address who);

    constructor(address admin, address registrar, address compliance) {
        if (admin == address(0) || registrar == address(0) || compliance == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, registrar);
        _grantRole(COMPLIANCE_ROLE, compliance);
    }

    // ---------------------------------------------------------------- merchants
    function registerMerchant(address merchant, string calldata name, uint16 categoryMask, bytes32 licenceHash)
        external
        onlyRole(REGISTRAR_ROLE)
    {
        if (merchant == address(0)) revert ZeroAddress();
        uint256 n = bytes(name).length;
        if (n == 0 || n > 64) revert InvalidName();
        if (categoryMask == 0) revert InvalidCategoryMask();
        if (licenceHash == bytes32(0)) revert InvalidHash();
        if (_merchants[merchant].approved) revert AlreadyRegistered(merchant);

        _merchants[merchant] = Merchant(true, false, categoryMask, licenceHash, name);
        _merchantList.push(merchant);
        emit MerchantRegistered(merchant, name, categoryMask, licenceHash);
    }

    function updateMerchantCategories(address merchant, uint16 categoryMask) external onlyRole(REGISTRAR_ROLE) {
        if (!_merchants[merchant].approved) revert NotRegistered(merchant);
        if (categoryMask == 0) revert InvalidCategoryMask();
        _merchants[merchant].categoryMask = categoryMask;
        emit MerchantCategoriesUpdated(merchant, categoryMask);
    }

    function setMerchantSuspended(address merchant, bool suspended) external onlyRole(COMPLIANCE_ROLE) {
        if (!_merchants[merchant].approved) revert NotRegistered(merchant);
        _merchants[merchant].suspended = suspended;
        emit MerchantSuspensionChanged(merchant, suspended);
    }

    // ------------------------------------------------------------ beneficiaries
    function registerBeneficiary(address wallet, bytes32 idHash) external onlyRole(REGISTRAR_ROLE) {
        if (wallet == address(0)) revert ZeroAddress();
        if (idHash == bytes32(0)) revert InvalidHash();
        if (_beneficiaries[wallet].registered) revert AlreadyRegistered(wallet);
        if (walletOfIdHash[idHash] != address(0)) revert DuplicateIdentity(idHash);

        _beneficiaries[wallet] = Beneficiary(true, false, idHash);
        walletOfIdHash[idHash] = wallet;
        _beneficiaryList.push(wallet);
        emit BeneficiaryRegistered(wallet, idHash);
    }

    function setBeneficiaryFrozen(address wallet, bool frozen) external onlyRole(COMPLIANCE_ROLE) {
        if (!_beneficiaries[wallet].registered) revert NotRegistered(wallet);
        _beneficiaries[wallet].frozen = frozen;
        emit BeneficiaryFreezeChanged(wallet, frozen);
    }

    // -------------------------------------------------------------------- views
    function isBeneficiaryActive(address wallet) public view returns (bool) {
        Beneficiary storage b = _beneficiaries[wallet];
        return b.registered && !b.frozen;
    }

    function isMerchantEligible(address merchant, uint8 category) public view returns (bool) {
        Merchant storage m = _merchants[merchant];
        return m.approved && !m.suspended && category <= MAX_CATEGORY && ((m.categoryMask >> category) & 1) == 1;
    }

    function getMerchant(address merchant) external view returns (Merchant memory) {
        return _merchants[merchant];
    }

    function getBeneficiary(address wallet) external view returns (Beneficiary memory) {
        return _beneficiaries[wallet];
    }

    function merchantCount() external view returns (uint256) {
        return _merchantList.length;
    }

    function beneficiaryCount() external view returns (uint256) {
        return _beneficiaryList.length;
    }

    function merchantAt(uint256 i) external view returns (address) {
        return _merchantList[i];
    }

    function beneficiaryAt(uint256 i) external view returns (address) {
        return _beneficiaryList[i];
    }
}
