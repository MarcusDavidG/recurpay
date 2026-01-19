// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract SubscriptionFactoryTest is Test {
    SubscriptionFactory public factory;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public user = address(0x2);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;

    function setUp() public {
        factory = new SubscriptionFactory(owner);
        token = new MockERC20("Test Token", "TEST", 18);
        
        // Add token to supported list
        factory.setSupportedToken(address(token), true);
    }

    function _createDefaultPlanConfig() internal view returns (ISubscriptionFactory.PlanConfig memory) {
        return ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });
    }

    function _createDefaultPlanMetadata() internal pure returns (ISubscriptionFactory.PlanMetadata memory) {
        return ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "A test subscription plan",
            metadataURI: "ipfs://test"
        });
    }

    // =========================================================================
    // Plan Creation Tests
    // =========================================================================

    function test_CreatePlan_Success() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        uint256 planId = factory.createPlan(config, metadata);

        assertEq(planId, 1);
        assertEq(factory.totalPlans(), 1);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertEq(storedConfig.creator, creator);
        assertEq(storedConfig.price, PRICE);
        assertEq(storedConfig.billingPeriod, BILLING_PERIOD);
        assertTrue(storedConfig.active);
    }

    function test_CreatePlan_MultiplePlans() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        uint256 planId1 = factory.createPlan(config, metadata);
        uint256 planId2 = factory.createPlan(config, metadata);
        uint256 planId3 = factory.createPlan(config, metadata);

        assertEq(planId1, 1);
        assertEq(planId2, 2);
        assertEq(planId3, 3);
        assertEq(factory.totalPlans(), 3);
    }

    function test_CreatePlan_WithETH() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.paymentToken = address(0); // ETH
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        uint256 planId = factory.createPlan(config, metadata);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertEq(storedConfig.paymentToken, address(0));
    }

    function test_CreatePlan_RevertZeroCreator() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.creator = address(0);
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert();
        factory.createPlan(config, metadata);
    }

    function test_CreatePlan_RevertZeroPrice() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.price = 0;
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert(ISubscriptionFactory.InvalidPrice.selector);
        factory.createPlan(config, metadata);
    }

    function test_CreatePlan_RevertInvalidBillingPeriod() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.billingPeriod = 1 minutes; // Too short
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert(ISubscriptionFactory.InvalidBillingPeriod.selector);
        factory.createPlan(config, metadata);
    }

    function test_CreatePlan_RevertUnsupportedToken() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.paymentToken = address(0x999); // Not supported
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert(ISubscriptionFactory.UnsupportedPaymentToken.selector);
        factory.createPlan(config, metadata);
    }

    // =========================================================================
    // Plan Update Tests
    // =========================================================================

    function test_UpdatePlanPrice_Success() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        uint256 newPrice = 20 ether;
        vm.prank(creator);
        factory.updatePlanPrice(planId, newPrice);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertEq(storedConfig.price, newPrice);
    }

    function test_UpdatePlanPrice_RevertNotCreator() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(user);
        vm.expectRevert(ISubscriptionFactory.NotPlanCreator.selector);
        factory.updatePlanPrice(planId, 20 ether);
    }

    function test_UpdatePlanPrice_RevertZeroPrice() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(creator);
        vm.expectRevert(ISubscriptionFactory.InvalidPrice.selector);
        factory.updatePlanPrice(planId, 0);
    }

    function test_SetPlanActive_Deactivate() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(creator);
        factory.setPlanActive(planId, false);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertFalse(storedConfig.active);
    }

    function test_SetPlanActive_Reactivate() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.startPrank(creator);
        factory.setPlanActive(planId, false);
        factory.setPlanActive(planId, true);
        vm.stopPrank();

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertTrue(storedConfig.active);
    }

    function test_SetPlanActive_RevertNotCreator() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(user);
        vm.expectRevert(ISubscriptionFactory.NotPlanCreator.selector);
        factory.setPlanActive(planId, false);
    }

    // =========================================================================
    // Token Whitelist Tests
    // =========================================================================

    function test_SetSupportedToken_Add() public {
        address newToken = address(0x123);
        
        assertFalse(factory.supportedTokens(newToken));
        
        factory.setSupportedToken(newToken, true);
        
        assertTrue(factory.supportedTokens(newToken));
    }

    function test_SetSupportedToken_Remove() public {
        factory.setSupportedToken(address(token), false);
        
        assertFalse(factory.supportedTokens(address(token)));
    }

    function test_SetSupportedToken_RevertNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        factory.setSupportedToken(address(0x123), true);
    }

    function test_SetSupportedToken_RevertETH() public {
        vm.expectRevert();
        factory.setSupportedToken(address(0), false);
    }

    function test_ETH_AlwaysSupported() public view {
        assertTrue(factory.supportedTokens(address(0)));
    }

    // =========================================================================
    // Query Tests
    // =========================================================================

    function test_GetCreatorPlans() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        factory.createPlan(config, metadata);
        factory.createPlan(config, metadata);

        uint256[] memory plans = factory.getCreatorPlans(creator);
        assertEq(plans.length, 2);
        assertEq(plans[0], 1);
        assertEq(plans[1], 2);
    }

    function test_GetPlanMetadata() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        ISubscriptionFactory.PlanMetadata memory storedMetadata = factory.getPlanMetadata(planId);
        assertEq(storedMetadata.name, "Test Plan");
        assertEq(storedMetadata.description, "A test subscription plan");
    }

    function test_GetPlan_RevertNotFound() public {
        vm.expectRevert(ISubscriptionFactory.PlanNotFound.selector);
        factory.getPlan(999);
    }
}
