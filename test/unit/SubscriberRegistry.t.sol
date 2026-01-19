// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract SubscriberRegistryTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public processor = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;

    uint256 public planId;

    function setUp() public {
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        token = new MockERC20("Test Token", "TEST", 18);

        factory.setSupportedToken(address(token), true);
        registry.setProcessor(processor);

        // Create a default plan
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
    }

    // =========================================================================
    // Subscription Creation Tests
    // =========================================================================

    function test_Subscribe_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        assertEq(subId, 1);
        assertEq(registry.totalSubscriptions(), 1);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(sub.planId, planId);
        assertEq(sub.subscriber, subscriber);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Active));
    }

    function test_Subscribe_MultipleSubscribers() public {
        address subscriber2 = address(0x4);
        address subscriber3 = address(0x5);

        uint256 subId1 = registry.subscribe(planId, subscriber);
        uint256 subId2 = registry.subscribe(planId, subscriber2);
        uint256 subId3 = registry.subscribe(planId, subscriber3);

        assertEq(subId1, 1);
        assertEq(subId2, 2);
        assertEq(subId3, 3);
        assertEq(registry.getPlanSubscriberCount(planId), 3);
    }

    function test_Subscribe_RevertAlreadySubscribed() public {
        registry.subscribe(planId, subscriber);

        vm.expectRevert(ISubscriberRegistry.AlreadySubscribed.selector);
        registry.subscribe(planId, subscriber);
    }

    function test_Subscribe_RevertZeroAddress() public {
        vm.expectRevert();
        registry.subscribe(planId, address(0));
    }

    function test_Subscribe_RevertPlanNotActive() public {
        vm.prank(creator);
        factory.setPlanActive(planId, false);

        vm.expectRevert(ISubscriptionFactory.PlanNotActive.selector);
        registry.subscribe(planId, subscriber);
    }

    function test_Subscribe_RevertPlanAtCapacity() public {
        // Create plan with max 1 subscriber
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 1,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Limited Plan",
            description: "",
            metadataURI: ""
        });

        uint256 limitedPlanId = factory.createPlan(config, metadata);

        registry.subscribe(limitedPlanId, subscriber);

        vm.expectRevert(ISubscriberRegistry.PlanAtCapacity.selector);
        registry.subscribe(limitedPlanId, address(0x4));
    }
}
