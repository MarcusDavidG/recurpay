// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RecurPayEvents
/// @author RecurPay Protocol
/// @notice Shared event definitions for the RecurPay protocol
library RecurPayEvents {
    // =========================================================================
    // Protocol Events
    // =========================================================================

    /// @notice Emitted when protocol is initialized
    /// @param admin Initial admin address
    /// @param treasury Treasury address for fees
    event ProtocolInitialized(address indexed admin, address indexed treasury);

    /// @notice Emitted when protocol is paused
    /// @param caller Address that triggered pause
    event ProtocolPaused(address indexed caller);

    /// @notice Emitted when protocol is unpaused
    /// @param caller Address that triggered unpause
    event ProtocolUnpaused(address indexed caller);

    /// @notice Emitted when admin is changed
    /// @param oldAdmin Previous admin address
    /// @param newAdmin New admin address
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    /// @notice Emitted when treasury is changed
    /// @param oldTreasury Previous treasury address
    /// @param newTreasury New treasury address
    event TreasuryChanged(address indexed oldTreasury, address indexed newTreasury);

    /// @notice Emitted when a token is added to supported list
    /// @param token Token address
    /// @param oracle Price oracle for token (if applicable)
    event TokenAdded(address indexed token, address indexed oracle);

    /// @notice Emitted when a token is removed from supported list
    /// @param token Token address
    event TokenRemoved(address indexed token);

    /// @notice Emitted when processor is authorized
    /// @param processor Processor address
    event ProcessorAuthorized(address indexed processor);

    /// @notice Emitted when processor authorization is revoked
    /// @param processor Processor address
    event ProcessorRevoked(address indexed processor);

    // =========================================================================
    // Fee Events
    // =========================================================================

    /// @notice Emitted when protocol fee is collected
    /// @param token Fee token
    /// @param amount Fee amount
    /// @param source Source of fee (subscription ID)
    event ProtocolFeeCollected(
        address indexed token,
        uint256 amount,
        uint256 indexed source
    );

    /// @notice Emitted when fees are withdrawn to treasury
    /// @param token Token withdrawn
    /// @param amount Amount withdrawn
    /// @param treasury Treasury address
    event FeesWithdrawn(
        address indexed token,
        uint256 amount,
        address indexed treasury
    );
}
