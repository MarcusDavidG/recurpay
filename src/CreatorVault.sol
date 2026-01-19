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

    /// @notice Sets the authorized payment processor
    /// @param processor Address of the PaymentProcessor contract
    function setPaymentProcessor(address processor) external onlyOwner {
        if (processor == address(0)) revert RecurPayErrors.ZeroAddress();
        paymentProcessor = processor;
        emit PaymentProcessorSet(processor);
    }

    // ========================================================================
    // External Functions - Vault Management
    // ========================================================================

    /// @inheritdoc ICreatorVault
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

    /// @inheritdoc ICreatorVault
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

    /// @inheritdoc ICreatorVault
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
}
