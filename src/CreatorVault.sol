// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CreatorVault
/// @author RecurPay Protocol
/// @notice Manages creator revenue and withdrawals
contract CreatorVault is ICreatorVault, RecurPayBase {
    using SafeERC20 for IERC20;

    // ========================================================================
    // State Variables
    // ========================================================================

    /// @notice Address authorized to deposit (PaymentProcessor)
    address public paymentProcessor;

    /// @notice Vault counter for unique IDs
    uint256 private _vaultCounter;

    /// @notice Creator address => vault exists
    mapping(address => bool) private _hasVault;

    /// @notice Creator address => vault ID
    mapping(address => uint256) private _vaultIds;

    /// @notice Creator => token => balance
    mapping(address => mapping(address => uint256)) private _balances;

    /// @notice Creator => withdrawal recipient
    mapping(address => address) private _withdrawalAddresses;

    /// @notice Creator => list of tokens with balance
    mapping(address => address[]) private _creatorTokens;

    /// @notice Creator => token => exists in list
    mapping(address => mapping(address => bool)) private _tokenExists;

    /// @notice Creator => revenue stats
    mapping(address => RevenueStats) private _revenueStats;

    /// @notice Creator => auto-withdrawal enabled
    mapping(address => bool) private _autoWithdrawEnabled;

    /// @notice Creator => auto-withdrawal threshold
    mapping(address => uint256) private _autoWithdrawThreshold;

    // ========================================================================
    // Events
    // ========================================================================

    event PaymentProcessorSet(address indexed processor);
    event VaultCreated(address indexed creator, uint256 indexed vaultId);

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor(address initialOwner) RecurPayBase(initialOwner) {}

    // ========================================================================
    // Admin Functions
    // ========================================================================

    /// @notice Sets the authorized payment processor.
    /// @param processor Address of the PaymentProcessor contract.
    function setPaymentProcessor(address processor) external onlyOwner {
        if (processor == address(0)) revert RecurPayErrors.ZeroAddress();
        paymentProcessor = processor;
        emit PaymentProcessorSet(processor);
    }

    // ========================================================================
    // External Functions - Vault Management
    // ========================================================================

    /// @notice Creates a new vault for a creator.
    /// @param creator The address of the creator for whom to create the vault.
    /// @return vaultId The ID of the newly created vault.
    function createVault(address creator) external returns (uint256 vaultId) {
        if (creator == address(0)) revert RecurPayErrors.ZeroAddress();
        if (_hasVault[creator]) revert RecurPayErrors.VaultAlreadyExists();

        vaultId = ++_vaultCounter;
        _hasVault[creator] = true;
        _vaultIds[creator] = vaultId;
        _withdrawalAddresses[creator] = creator;

        emit VaultCreated(creator, vaultId);
        return vaultId;
    }

    /// @notice Checks if a creator has a vault.
    /// @param creator The address of the creator.
    /// @return exists True if the creator has a vault, false otherwise.
    function hasVault(address creator) external view returns (bool exists) {
        return _hasVault[creator];
    }

    // ========================================================================
    // Modifiers
    // ========================================================================

    /// @notice Ensures caller is the payment processor
    modifier onlyProcessor() {
        if (msg.sender != paymentProcessor) revert RecurPayErrors.NotProcessor();
        _;
    }

    /// @notice Ensures caller owns the vault
    modifier onlyVaultOwner(address creator) {
        if (msg.sender != creator) revert ICreatorVault.NotVaultOwner();
        if (!_hasVault[creator]) revert ICreatorVault.VaultNotFound();
        _;
    }

    // ========================================================================
    // External Functions - Deposits
    // ========================================================================

    /// @notice Deposits funds into a creator's vault. Only callable by the payment processor.
    /// @param creator The address of the creator.
    /// @param token The address of the token being deposited (address(0) for ETH).
    /// @param amount The amount of tokens or ETH to deposit.
    /// @param subscriptionId The ID of the subscription associated with the deposit.
    function deposit(
        address creator,
        address token,
        uint256 amount,
        uint256 subscriptionId
    ) external payable onlyProcessor nonReentrant {
        if (creator == address(0)) revert RecurPayErrors.ZeroAddress();
        if (amount == 0) revert ICreatorVault.ZeroDeposit();

        // Auto-create vault if doesn't exist
        if (!_hasVault[creator]) {
            uint256 vaultId = ++_vaultCounter;
            _hasVault[creator] = true;
            _vaultIds[creator] = vaultId;
            _withdrawalAddresses[creator] = creator;
            emit VaultCreated(creator, vaultId);
        }

        // Handle ETH deposits
        if (token == address(0)) {
            if (msg.value != amount) revert RecurPayErrors.InsufficientBalance();
        }

        // Track token if new
        if (!_tokenExists[creator][token]) {
            _creatorTokens[creator].push(token);
            _tokenExists[creator][token] = true;
        }

        // Update balances
        _balances[creator][token] += amount;

        // Update revenue stats
        RevenueStats storage stats = _revenueStats[creator];
        stats.totalRevenue += amount;
        stats.pendingBalance += amount;

        emit RevenueDeposited(creator, token, amount, subscriptionId);

        // Check auto-withdrawal
        if (_autoWithdrawEnabled[creator] && _balances[creator][token] >= _autoWithdrawThreshold[creator]) {
            _executeWithdrawal(creator, token, _balances[creator][token]);
        }
    }

    /// @notice Internal withdrawal execution
    function _executeWithdrawal(address creator, address token, uint256 amount) internal {
        address recipient = _withdrawalAddresses[creator];

        _balances[creator][token] -= amount;
        _revenueStats[creator].pendingBalance -= amount;
        _revenueStats[creator].totalWithdrawn += amount;

        if (token == address(0)) {
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert ICreatorVault.TransferFailed();
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }

        emit FundsWithdrawn(creator, token, amount, recipient);
    }

    // ========================================================================
    // External Functions - Withdrawals
    // ========================================================================

    /// @notice Withdraws a specified amount of tokens from the creator's vault.
    /// @param token The address of the token to withdraw (address(0) for ETH).
    /// @param amount The amount of tokens or ETH to withdraw.
    function withdraw(address token, uint256 amount) external nonReentrant onlyVaultOwner(msg.sender) {
        if (amount == 0) revert RecurPayErrors.ZeroAmount();
        if (_balances[msg.sender][token] < amount) revert ICreatorVault.InsufficientVaultBalance();

        _executeWithdrawal(msg.sender, token, amount);
    }

    /// @notice Withdraws all available balance of a specific token from the creator's vault.
    /// @param token The address of the token to withdraw (address(0) for ETH).
    function withdrawAll(address token) external nonReentrant onlyVaultOwner(msg.sender) {
        uint256 balance = _balances[msg.sender][token];
        if (balance == 0) revert ICreatorVault.InsufficientVaultBalance();

        _executeWithdrawal(msg.sender, token, balance);
    }

    /// @notice Sets the withdrawal address for a creator's vault.
    /// @param recipient The new address to which funds will be withdrawn.
    function setWithdrawalAddress(address recipient) external onlyVaultOwner(msg.sender) {
        if (recipient == address(0)) revert ICreatorVault.InvalidWithdrawalAddress();

        address oldRecipient = _withdrawalAddresses[msg.sender];
        _withdrawalAddresses[msg.sender] = recipient;

        emit WithdrawalAddressUpdated(msg.sender, oldRecipient, recipient);
    }

    // ========================================================================
    // External Functions - Balance Queries
    // ========================================================================

    /// @notice Gets the balance of a specific token for a creator's vault.
    /// @param creator The address of the creator.
    /// @param token The address of the token (address(0) for ETH).
    /// @return balance The balance of the token.
    function getBalance(address creator, address token) external view returns (uint256 balance) {
        return _balances[creator][token];
    }

    /// @notice Gets all non-zero token balances for a creator's vault.
    /// @param creator The address of the creator.
    /// @return balances An array of TokenBalance structs, each containing token address and its balance.
    function getAllBalances(address creator) external view returns (TokenBalance[] memory balances) {
        address[] memory tokens = _creatorTokens[creator];
        uint256 count = 0;

        // Count non-zero balances
        for (uint256 i = 0; i < tokens.length; i++) {
            if (_balances[creator][tokens[i]] > 0) {
                count++;
            }
        }

        balances = new TokenBalance[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 bal = _balances[creator][tokens[i]];
            if (bal > 0) {
                balances[index] = TokenBalance({
                    token: tokens[i],
                    balance: bal,
                    lastUpdated: uint64(block.timestamp)
                });
                index++;
            }
        }

        return balances;
    }

    /// @notice Gets the withdrawal address configured for a creator's vault.
    /// @param creator The address of the creator.
    /// @return recipient The withdrawal address.
    function getWithdrawalAddress(address creator) external view returns (address recipient) {
        return _withdrawalAddresses[creator];
    }

    // ========================================================================
    // External Functions - Auto-Withdrawal
    // ========================================================================

    /// @notice Configures the automatic withdrawal settings for a creator's vault.
    /// @param enabled Whether to enable or disable auto-withdrawal.
    /// @param threshold The minimum balance required to trigger an auto-withdrawal.
    function configureAutoWithdrawal(bool enabled, uint256 threshold) external onlyVaultOwner(msg.sender) {
        _autoWithdrawEnabled[msg.sender] = enabled;
        _autoWithdrawThreshold[msg.sender] = threshold;

        emit AutoWithdrawalConfigured(msg.sender, enabled, threshold);
    }

    /// @notice Gets auto-withdrawal configuration for a creator
    /// @param creator Creator address
    /// @return enabled Whether auto-withdrawal is enabled
    /// @return threshold Minimum balance to trigger
    function getAutoWithdrawalConfig(address creator) external view returns (bool enabled, uint256 threshold) {
        return (_autoWithdrawEnabled[creator], _autoWithdrawThreshold[creator]);
    }

    // ========================================================================
    // External Functions - Revenue Statistics
    // ========================================================================

    /// @notice Gets the revenue statistics for a creator.
    /// @param creator The address of the creator.
    /// @return stats The revenue statistics of the creator.
    function getRevenueStats(address creator) external view returns (RevenueStats memory stats) {
        return _revenueStats[creator];
    }

    /// @notice Updates the subscriber count for a creator. Can only be called by the payment processor.
    /// @param creator The address of the creator.
    /// @param count The new subscriber count.
    function updateSubscriberCount(address creator, uint32 count) external onlyProcessor {
        _revenueStats[creator].subscriberCount = count;
    }

    /// @notice Gets the vault ID for a creator.
    /// @param creator The address of the creator.
    /// @return vaultId The vault identifier.
    function getVaultId(address creator) external view returns (uint256 vaultId) {
        if (!_hasVault[creator]) revert ICreatorVault.VaultNotFound();
        return _vaultIds[creator];
    }

    /// @notice Returns total number of vaults created
    /// @return count Total vault count
    function totalVaults() external view returns (uint256 count) {
        return _vaultCounter;
    }

    /// @notice Allows contract to receive ETH
    receive() external payable {}
}
