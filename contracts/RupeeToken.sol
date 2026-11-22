// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RupeeToken (simulated e-rupee)
 * @notice A SIMULATED central-bank-money token used only to demonstrate PurposePay.
 *         It is NOT the RBI's Digital Rupee. 2 decimals = paise (1 token unit = 1 paisa).
 *         Only an address holding ISSUER_ROLE (standing in for the central bank) can create
 *         tokens. Holders can redeem (burn) tokens, which emits an event that an off-chain
 *         bank adapter would use to credit the holder's bank account.
 */
contract RupeeToken is ERC20, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    event Issued(address indexed to, uint256 amount, bytes32 ledgerRef);
    event Redeemed(address indexed from, uint256 amount, bytes32 bankReference);

    error ZeroAddress();
    error ZeroAmount();

    constructor(address admin, address issuer) ERC20("Simulated Digital Rupee", "eRS") {
        if (admin == address(0) || issuer == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, issuer);
    }

    function decimals() public pure override returns (uint8) {
        return 2;
    }

    /// @notice Create new simulated e-rupee. `ledgerRef` links the issue to an off-chain RTGS/ledger entry.
    function issue(address to, uint256 amount, bytes32 ledgerRef) external onlyRole(ISSUER_ROLE) {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        _mint(to, amount);
        emit Issued(to, amount, ledgerRef);
    }

    /// @notice Burn tokens held by the caller; an off-chain bank adapter credits the bank account.
    function redeem(uint256 amount, bytes32 bankReference) external {
        if (amount == 0) revert ZeroAmount();
        _burn(msg.sender, amount);
        emit Redeemed(msg.sender, amount, bankReference);
    }
}
