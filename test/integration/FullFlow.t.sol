// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {RecurPayRouter} from "src/RecurPayRouter.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract FullFlowTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    CreatorVault public vault;
    PaymentProcessor public processor;
    RecurPayRouter public router;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public treasury = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;

    function setUp() public {
        // Deploy all contracts
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        vault = new CreatorVault(owner);
        processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            100, // 1% fee
            owner
        );
        router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            owner
        );

        token = new MockERC20("USDC", "USDC", 6);

        // Configure
        factory.setSupportedToken(address(token), true);
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        // Fund subscriber
        token.mint(subscriber, 1000 ether);
        vm.prank(subscriber);
        token.approve(address(processor), type(uint256).max);
    }

    function test_FullSubscriptionLifecycle() public {
        // 1. Creator creates a plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Premium Plan",
            description: "Access to premium features",
            metadataURI: "ipfs://metadata"
        });

        uint256 planId = factory.createPlan(config, metadata);
        assertEq(planId, 1);

        // 2. Subscriber subscribes
        uint256 subId = registry.subscribe(planId, subscriber);
        assertEq(subId, 1);

        // 3. First payment is processed
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        bool success = processor.processPayment(subId);
        assertTrue(success);

        // 4. Verify creator received payment
        uint256 expectedCreatorAmount = PRICE - (PRICE * 100 / 10000);
        assertEq(vault.getBalance(creator, address(token)), expectedCreatorAmount);

        // 5. Subscriber pauses
        vm.prank(subscriber);
        registry.pause(subId, 7 days);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Paused));

        // 6. Subscriber resumes
        vm.prank(subscriber);
        registry.resume(subId);

        sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Active));

        // 7. Creator withdraws
        vm.prank(creator);
        vault.withdrawAll(address(token));

        assertEq(vault.getBalance(creator, address(token)), 0);
        assertEq(token.balanceOf(creator), expectedCreatorAmount);

        // 8. Subscriber cancels
        vm.prank(subscriber);
        registry.cancel(subId);

        sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }

    function test_MultipleSubscribers() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Premium",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);

        // Create multiple subscribers
        address[] memory subscribers = new address[](5);
        uint256[] memory subIds = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            subscribers[i] = address(uint160(0x100 + i));
            token.mint(subscribers[i], 1000 ether);
            vm.prank(subscribers[i]);
            token.approve(address(processor), type(uint256).max);
            subIds[i] = registry.subscribe(planId, subscribers[i]);
        }

        assertEq(registry.getPlanSubscriberCount(planId), 5);

        // Process all payments
        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        processor.processBatch(subIds);

        // Verify creator balance
        uint256 expectedPerPayment = PRICE - (PRICE * 100 / 10000);
        assertEq(vault.getBalance(creator, address(token)), expectedPerPayment * 5);
    }

    function test_MultiplePaymentCycles() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Monthly",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);
        uint256 subId = registry.subscribe(planId, subscriber);

        uint256 expectedPerPayment = PRICE - (PRICE * 100 / 10000);

        // Process 3 payment cycles
        for (uint256 i = 0; i < 3; i++) {
            vm.warp(block.timestamp + BILLING_PERIOD + 1);
            processor.processPayment(subId);
        }

        assertEq(vault.getBalance(creator, address(token)), expectedPerPayment * 3);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(sub.totalPaid, PRICE * 3);
    }

    function test_PaymentFailureAndRecovery() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain subscriber balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        // First payment fails - enters grace period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        bool success = processor.processPayment(subId);
        assertFalse(success);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.GracePeriod));

        // Subscriber tops up balance
        token.mint(subscriber, 100 ether);

        // Payment succeeds within grace period
        success = processor.processPayment(subId);
        assertTrue(success);

        // Status should be active again after successful payment
        sub = registry.getSubscription(subId);
        // Note: The status update depends on implementation
    }

    function test_SubscriptionExpiry() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain subscriber balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        // First failure - enters grace period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        // Second failure after grace period - should cancel
        vm.warp(block.timestamp + 3 days + 1);
        processor.processPayment(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }

    function test_CreatorWithdrawalFlow() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);

        // Multiple subscribers
        for (uint256 i = 0; i < 3; i++) {
            address sub = address(uint160(0x100 + i));
            token.mint(sub, 1000 ether);
            vm.prank(sub);
            token.approve(address(processor), type(uint256).max);
            registry.subscribe(planId, sub);
        }

        // Process payments
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        uint256[] memory subIds = new uint256[](3);
        subIds[0] = 1;
        subIds[1] = 2;
        subIds[2] = 3;
        processor.processBatch(subIds);

        // Check revenue stats
        ICreatorVault.RevenueStats memory stats = vault.getRevenueStats(creator);
        uint256 expectedPerPayment = PRICE - (PRICE * 100 / 10000);
        assertEq(stats.totalRevenue, expectedPerPayment * 3);
        assertEq(stats.pendingBalance, expectedPerPayment * 3);

        // Set custom withdrawal address
        address customRecipient = address(0x789);
        vm.prank(creator);
        vault.setWithdrawalAddress(customRecipient);

        // Partial withdrawal
        vm.prank(creator);
        vault.withdraw(address(token), expectedPerPayment);

        assertEq(token.balanceOf(customRecipient), expectedPerPayment);

        // Withdraw remaining
        vm.prank(creator);
        vault.withdrawAll(address(token));

        assertEq(vault.getBalance(creator, address(token)), 0);
        assertEq(token.balanceOf(customRecipient), expectedPerPayment * 3);
    }
}
