// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {IPaymentProcessor} from "src/interfaces/IPaymentProcessor.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title RecurPayRouter
/// @author RecurPay Protocol
/// @notice Unified entry point for RecurPay protocol interactions
contract RecurPayRouter is RecurPayBase {
    using SafeERC20 for IERC20;

    // ========================================================================
    // State Variables
    // ========================================================================

    ISubscriptionFactory public subscriptionFactory;
    ISubscriberRegistry public subscriberRegistry;
    IPaymentProcessor public paymentProcessor;
    ICreatorVault public creatorVault;

    // ========================================================================
    // Events
    // ========================================================================

    event ContractsUpdated(
        address indexed factory,
        address indexed registry,
        address indexed processor,
        address vault
    );

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor(
        address factory,
        address registry,
        address processor,
        address vault,
        address initialOwner
    ) RecurPayBase(initialOwner) {
        if (factory == address(0)) revert RecurPayErrors.ZeroAddress();
        if (registry == address(0)) revert RecurPayErrors.ZeroAddress();
        if (processor == address(0)) revert RecurPayErrors.ZeroAddress();
        if (vault == address(0)) revert RecurPayErrors.ZeroAddress();

        subscriptionFactory = ISubscriptionFactory(factory);
        subscriberRegistry = ISubscriberRegistry(registry);
        paymentProcessor = IPaymentProcessor(processor);
        creatorVault = ICreatorVault(vault);
    }

    // ========================================================================
    // Admin Functions
    // ========================================================================

    /// @notice Updates protocol contract references
    function updateContracts(
        address factory,
        address registry,
        address processor,
        address vault
    ) external onlyOwner {
        if (factory != address(0)) subscriptionFactory = ISubscriptionFactory(factory);
        if (registry != address(0)) subscriberRegistry = ISubscriberRegistry(registry);
        if (processor != address(0)) paymentProcessor = IPaymentProcessor(processor);
        if (vault != address(0)) creatorVault = ICreatorVault(vault);

        emit ContractsUpdated(
            address(subscriptionFactory),
            address(subscriberRegistry),
            address(paymentProcessor),
            address(creatorVault)
        );
    }
}
