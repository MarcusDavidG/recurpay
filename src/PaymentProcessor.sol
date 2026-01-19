// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {IPaymentProcessor} from "src/interfaces/IPaymentProcessor.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";
import {BillingPeriod} from "src/libraries/BillingPeriod.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title PaymentProcessor
/// @author RecurPay Protocol
/// @notice Processes recurring subscription payments
contract PaymentProcessor is IPaymentProcessor, RecurPayBase {
    using SafeERC20 for IERC20;

    // ========================================================================
    // Constants
    // ========================================================================

    /// @notice Maximum protocol fee (10%)
    uint16 public constant MAX_FEE_BPS = 1000;

    /// @notice Maximum batch size for processing
    uint32 public constant MAX_BATCH_SIZE = 100;

    // ========================================================================
    // State Variables
    // ========================================================================

    /// @notice Reference to SubscriptionFactory
    ISubscriptionFactory public subscriptionFactory;

    /// @notice Reference to SubscriberRegistry
    ISubscriberRegistry public subscriberRegistry;

    /// @notice Reference to CreatorVault
    ICreatorVault public creatorVault;

    /// @notice Protocol fee in basis points
    uint16 private _protocolFeeBps;

    /// @notice Treasury address for protocol fees
    address public treasury;

    /// @notice Subscription ID => payment history
    mapping(uint256 => PaymentExecution[]) private _paymentHistory;

    /// @notice Accumulated protocol fees per token
    mapping(address => uint256) private _protocolFees;

    // ========================================================================
    // Events
    // ========================================================================

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event ProtocolFeesWithdrawn(address indexed token, uint256 amount);

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor(
        address factory,
        address registry,
        address vault,
        address treasuryAddress,
        uint16 feeBps,
        address initialOwner
    ) RecurPayBase(initialOwner) {
        if (factory == address(0)) revert RecurPayErrors.ZeroAddress();
        if (registry == address(0)) revert RecurPayErrors.ZeroAddress();
        if (vault == address(0)) revert RecurPayErrors.ZeroAddress();
        if (treasuryAddress == address(0)) revert RecurPayErrors.ZeroAddress();
        if (feeBps > MAX_FEE_BPS) revert IPaymentProcessor.FeeTooHigh();

        subscriptionFactory = ISubscriptionFactory(factory);
        subscriberRegistry = ISubscriberRegistry(registry);
        creatorVault = ICreatorVault(vault);
        treasury = treasuryAddress;
        _protocolFeeBps = feeBps;
    }

    // ========================================================================
    // Admin Functions
    // ========================================================================

    /// @inheritdoc IPaymentProcessor
    function setProtocolFee(uint16 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) revert IPaymentProcessor.FeeTooHigh();

        uint16 oldFee = _protocolFeeBps;
        _protocolFeeBps = newFeeBps;

        emit ProtocolFeeUpdated(oldFee, newFeeBps);
    }

    /// @notice Updates the treasury address
    /// @param newTreasury New treasury address
    function setTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert RecurPayErrors.ZeroAddress();

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /// @inheritdoc IPaymentProcessor
    function protocolFeeBps() external view returns (uint16 feeBps) {
        return _protocolFeeBps;
    }

    /// @notice Withdraws accumulated protocol fees
    /// @param token Token to withdraw (address(0) for ETH)
    function withdrawProtocolFees(address token) external onlyOwner nonReentrant {
        uint256 amount = _protocolFees[token];
        if (amount == 0) revert RecurPayErrors.ZeroAmount();

        _protocolFees[token] = 0;

        if (token == address(0)) {
            (bool success, ) = treasury.call{value: amount}("");
            if (!success) revert RecurPayErrors.ETHTransferFailed();
        } else {
            IERC20(token).safeTransfer(treasury, amount);
        }

        emit ProtocolFeesWithdrawn(token, amount);
    }

    /// @notice Gets accumulated protocol fees for a token
    /// @param token Token address
    /// @return amount Accumulated fees
    function getAccumulatedFees(address token) external view returns (uint256 amount) {
        return _protocolFees[token];
    }
}
