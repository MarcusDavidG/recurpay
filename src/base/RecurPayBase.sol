// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";

/// @title RecurPayBase
/// @author RecurPay Protocol
/// @notice Base contract for RecurPay protocol components.
/// Provides core functionality for ownership, pausable state, and reentrancy protection.
abstract contract RecurPayBase is Ownable, Pausable, ReentrancyGuard {
    /// @notice Initializes the contract, setting the sender as the initial owner.
    /// @param initialOwner The address of the initial owner.
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }
}
