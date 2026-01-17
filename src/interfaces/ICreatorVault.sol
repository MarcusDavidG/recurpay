// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ICreatorVault
/// @author RecurPay Protocol
/// @notice Interface for creator revenue management vaults on Base
interface ICreatorVault {
    // =========================================================================
    // Structs
    // =========================================================================

    /// @notice Revenue statistics for a creator
    /// @param totalRevenue All-time revenue received
    /// @param totalWithdrawn Amount withdrawn by creator
    /// @param pendingBalance Current withdrawable balance
    /// @param subscriberCount Active subscriber count
    struct RevenueStats {
        uint256 totalRevenue;
        uint256 totalWithdrawn;
        uint256 pendingBalance;
        uint32 subscriberCount;
    }

    /// @notice Token balance in the vault
    /// @param token Token address (address(0) for ETH)
    /// @param balance Current balance
    /// @param lastUpdated Last update timestamp
    struct TokenBalance {
        address token;
        uint256 balance;
        uint64 lastUpdated;
    }

    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when revenue is deposited to a vault
    /// @param creator Creator address
    /// @param token Payment token
    /// @param amount Deposit amount
    /// @param subscriptionId Source subscription
    event RevenueDeposited(
        address indexed creator,
        address indexed token,
        uint256 amount,
        uint256 indexed subscriptionId
    );

    /// @notice Emitted when creator withdraws funds
    /// @param creator Creator address
    /// @param token Withdrawn token
    /// @param amount Withdrawn amount
    /// @param recipient Withdrawal recipient
    event FundsWithdrawn(
        address indexed creator,
        address indexed token,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when withdrawal address is updated
    /// @param creator Creator address
    /// @param oldRecipient Previous withdrawal address
    /// @param newRecipient New withdrawal address
    event WithdrawalAddressUpdated(
        address indexed creator,
        address oldRecipient,
        address newRecipient
    );

    /// @notice Emitted when auto-withdrawal is configured
    /// @param creator Creator address
    /// @param enabled Whether auto-withdrawal is enabled
    /// @param threshold Minimum balance to trigger withdrawal
    event AutoWithdrawalConfigured(
        address indexed creator,
        bool enabled,
        uint256 threshold
    );

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Thrown when caller is not the vault owner
    error NotVaultOwner();

    /// @notice Thrown when withdrawal amount exceeds balance
    error InsufficientVaultBalance();

    /// @notice Thrown when withdrawal address is zero
    error InvalidWithdrawalAddress();

    /// @notice Thrown when vault does not exist for creator
    error VaultNotFound();

    /// @notice Thrown when deposit amount is zero
    error ZeroDeposit();

    /// @notice Thrown when token transfer fails
    error TransferFailed();

    // =========================================================================
    // Functions
    // =========================================================================

    /// @notice Creates a vault for a creator (called automatically on first plan)
    /// @param creator Creator address
    /// @return vaultId Vault identifier
    function createVault(address creator) external returns (uint256 vaultId);

    /// @notice Deposits revenue into a creator's vault
    /// @param creator Creator address
    /// @param token Payment token
    /// @param amount Deposit amount
    /// @param subscriptionId Source subscription
    function deposit(
        address creator,
        address token,
        uint256 amount,
        uint256 subscriptionId
    ) external payable;

    /// @notice Withdraws funds from vault to configured recipient
    /// @param token Token to withdraw
    /// @param amount Amount to withdraw
    function withdraw(address token, uint256 amount) external;

    /// @notice Withdraws all funds of a specific token
    /// @param token Token to withdraw
    function withdrawAll(address token) external;

    /// @notice Sets the withdrawal recipient address
    /// @param recipient New recipient address
    function setWithdrawalAddress(address recipient) external;

    /// @notice Configures automatic withdrawal settings
    /// @param enabled Whether to enable auto-withdrawal
    /// @param threshold Minimum balance to trigger
    function configureAutoWithdrawal(bool enabled, uint256 threshold) external;

    /// @notice Gets revenue statistics for a creator
    /// @param creator Creator address
    /// @return stats Revenue statistics
    function getRevenueStats(address creator) external view returns (RevenueStats memory stats);

    /// @notice Gets token balance for a creator
    /// @param creator Creator address
    /// @param token Token address
    /// @return balance Current balance
    function getBalance(address creator, address token) external view returns (uint256 balance);

    /// @notice Gets all token balances for a creator
    /// @param creator Creator address
    /// @return balances Array of token balances
    function getAllBalances(address creator) external view returns (TokenBalance[] memory balances);

    /// @notice Gets the withdrawal address for a creator
    /// @param creator Creator address
    /// @return recipient Withdrawal recipient
    function getWithdrawalAddress(address creator) external view returns (address recipient);

    /// @notice Checks if a creator has a vault
    /// @param creator Creator address
    /// @return exists Whether vault exists
    function hasVault(address creator) external view returns (bool exists);
}
