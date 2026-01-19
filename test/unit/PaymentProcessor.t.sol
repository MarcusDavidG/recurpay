// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {IPaymentProcessor} from "src/interfaces/IPaymentProcessor.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract PaymentProcessorTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    CreatorVault public vault;
    PaymentProcessor public processor;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public treasury = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;
    uint16 public constant FEE_BPS = 100; // 1%

    uint256 public planId;

    function setUp() public {
        // Deploy contracts
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        vault = new CreatorVault(owner);
        processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            FEE_BPS,
            owner
        );

        token = new MockERC20("Test Token", "TEST", 18);

        // Configure
        factory.setSupportedToken(address(token), true);
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "",
            metadataURI: ""
        });

        planId = factory.createPlan(config, metadata);

        // Fund subscriber
        token.mint(subscriber, 1000 ether);
        vm.prank(subscriber);
        token.approve(address(processor), type(uint256).max);
    }

    // =========================================================================
    // Payment Processing Tests
    // =========================================================================

    function test_ProcessPayment_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Warp to after billing period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        uint256 creatorBalanceBefore = vault.getBalance(creator, address(token));

        bool success = processor.processPayment(subId);

        assertTrue(success);
        
        uint256 expectedCreatorAmount = PRICE - (PRICE * FEE_BPS / 10000);
        assertEq(vault.getBalance(creator, address(token)), creatorBalanceBefore + expectedCreatorAmount);
    }

    function test_ProcessPayment_CollectsProtocolFee() public {
        uint256 subId = registry.subscribe(planId, subscriber);
        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        processor.processPayment(subId);

        uint256 expectedFee = PRICE * FEE_BPS / 10000;
        assertEq(processor.getAccumulatedFees(address(token)), expectedFee);
    }

    function test_ProcessPayment_RevertNotDue() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.expectRevert(IPaymentProcessor.PaymentNotDue.selector);
        processor.processPayment(subId);
    }

    function test_ProcessPayment_RevertPaused() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.pause(subId, 7 days);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        vm.expectRevert(IPaymentProcessor.SubscriptionPaused.selector);
        processor.processPayment(subId);
    }

    function test_ProcessPayment_RevertCancelled() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.cancel(subId);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        vm.expectRevert(IPaymentProcessor.SubscriptionCancelled.selector);
        processor.processPayment(subId);
    }

    function test_ProcessPayment_InsufficientBalance() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain subscriber balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        bool success = processor.processPayment(subId);
        assertFalse(success);
    }

    // =========================================================================
    // Batch Payment Tests
    // =========================================================================

    function test_ProcessBatch_Success() public {
        address subscriber2 = address(0x4);
        address subscriber3 = address(0x5);

        token.mint(subscriber2, 1000 ether);
        token.mint(subscriber3, 1000 ether);

        vm.prank(subscriber2);
        token.approve(address(processor), type(uint256).max);
        vm.prank(subscriber3);
        token.approve(address(processor), type(uint256).max);

        uint256 subId1 = registry.subscribe(planId, subscriber);
        uint256 subId2 = registry.subscribe(planId, subscriber2);
        uint256 subId3 = registry.subscribe(planId, subscriber3);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        uint256[] memory subIds = new uint256[](3);
        subIds[0] = subId1;
        subIds[1] = subId2;
        subIds[2] = subId3;

        IPaymentProcessor.BatchResult memory result = processor.processBatch(subIds);

        assertEq(result.processed, 3);
        assertEq(result.succeeded, 3);
        assertEq(result.failed, 0);
        assertEq(result.totalAmount, PRICE * 3);
    }

    function test_ProcessBatch_PartialFailure() public {
        address subscriber2 = address(0x4);

        token.mint(subscriber2, 1000 ether);
        vm.prank(subscriber2);
        token.approve(address(processor), type(uint256).max);

        uint256 subId1 = registry.subscribe(planId, subscriber);
        uint256 subId2 = registry.subscribe(planId, subscriber2);

        // Drain subscriber1 balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        uint256[] memory subIds = new uint256[](2);
        subIds[0] = subId1;
        subIds[1] = subId2;

        IPaymentProcessor.BatchResult memory result = processor.processBatch(subIds);

        assertEq(result.processed, 2);
        assertEq(result.succeeded, 1);
        assertEq(result.failed, 1);
    }

    function test_ProcessBatch_RevertExceedsMaxSize() public {
        uint256[] memory subIds = new uint256[](101);

        vm.expectRevert(IPaymentProcessor.BatchSizeExceeded.selector);
        processor.processBatch(subIds);
    }

    // =========================================================================
    // Grace Period Tests
    // =========================================================================

    function test_GracePeriod_EntersOnFailure() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        processor.processPayment(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.GracePeriod));
    }

    function test_GracePeriod_CancelsAfterExpiry() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        // First failure - enters grace period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        // Second failure after grace period - cancels
        vm.warp(block.timestamp + GRACE_PERIOD + 1);
        processor.processPayment(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }

    // =========================================================================
    // Fee Tests
    // =========================================================================

    function test_SetProtocolFee() public {
        uint16 newFee = 200; // 2%

        processor.setProtocolFee(newFee);

        assertEq(processor.protocolFeeBps(), newFee);
    }

    function test_SetProtocolFee_RevertTooHigh() public {
        vm.expectRevert(IPaymentProcessor.FeeTooHigh.selector);
        processor.setProtocolFee(1001); // &gt; 10%
    }

    function test_WithdrawProtocolFees() public {
        uint256 subId = registry.subscribe(planId, subscriber);
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        uint256 fees = processor.getAccumulatedFees(address(token));
        uint256 treasuryBefore = token.balanceOf(treasury);

        processor.withdrawProtocolFees(address(token));

        assertEq(processor.getAccumulatedFees(address(token)), 0);
        assertEq(token.balanceOf(treasury), treasuryBefore + fees);
    }

    // =========================================================================
    // Query Tests
    // =========================================================================

    function test_IsPaymentDue() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        (bool isDue, uint256 amount) = processor.isPaymentDue(subId);
        assertFalse(isDue);
        assertEq(amount, 0);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        (isDue, amount) = processor.isPaymentDue(subId);
        assertTrue(isDue);
        assertEq(amount, PRICE);
    }

    function test_GetNextPaymentDue() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        uint64 dueDate = processor.getNextPaymentDue(subId);
        assertEq(dueDate, block.timestamp + BILLING_PERIOD);
    }

    function test_GetPaymentHistory() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        IPaymentProcessor.PaymentExecution[] memory history = processor.getPaymentHistory(subId, 10);
        assertEq(history.length, 1);
        assertTrue(history[0].success);
        assertEq(history[0].amount, PRICE);
    }
}
