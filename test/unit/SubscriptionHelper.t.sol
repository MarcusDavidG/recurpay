// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/helpers/SubscriptionHelper.sol";

contract SubscriptionHelperTest is Test {
    SubscriptionHelper helper;

    function setUp() public {
        helper = new SubscriptionHelper();
    }

    function testCalculateProRatedAmount() public {
        uint256 result = helper.calculateProRatedAmount(1000, 30, 15);
        assertEq(result, 500); // Half the amount for half the period
    }

    function testCalculateNextBillingDate() public {
        uint256 lastBilling = 1000;
        uint256 billingPeriod = 30 days;
        uint256 nextBilling = helper.calculateNextBillingDate(lastBilling, billingPeriod);
        assertEq(nextBilling, lastBilling + billingPeriod);
    }

    function testIsSubscriptionActive() public {
        uint256 lastPayment = block.timestamp - 10 days;
        uint256 billingPeriod = 30 days;
        uint256 gracePeriod = 5 days;
        
        assertTrue(helper.isSubscriptionActive(lastPayment, billingPeriod, gracePeriod));
        
        // Test expired subscription
        lastPayment = block.timestamp - 40 days;
        assertFalse(helper.isSubscriptionActive(lastPayment, billingPeriod, gracePeriod));
    }

    function testCalculateLateFee() public {
        uint256 lateFee = helper.calculateLateFee(1000, 10, 500); // 5% rate, 10 days late
        assertGt(lateFee, 0);
    }

    function testGenerateSubscriptionId() public {
        address creator = address(0x1);
        address subscriber = address(0x2);
        uint256 planId = 1;
        
        bytes32 id1 = helper.generateSubscriptionId(creator, subscriber, planId);
        bytes32 id2 = helper.generateSubscriptionId(creator, subscriber, planId);
        
        // Should be different due to timestamp
        assertNotEq(id1, id2);
    }

    function testValidateSubscriptionData() public {
        assertTrue(helper.validateSubscriptionData(1 ether, 30 days, address(0x1)));
        assertFalse(helper.validateSubscriptionData(0, 30 days, address(0x1))); // Zero price
        assertFalse(helper.validateSubscriptionData(1 ether, 0, address(0x1))); // Zero duration
        assertFalse(helper.validateSubscriptionData(1 ether, 30 days, address(0))); // Zero address
    }

    function testCalculateDiscount() public {
        uint256 discounted = helper.calculateDiscount(1000, 2000); // 20% discount
        assertEq(discounted, 800);
    }

    function testIsPaymentDue() public {
        uint256 lastPayment = block.timestamp - 31 days;
        uint256 billingPeriod = 30 days;
        
        assertTrue(helper.isPaymentDue(lastPayment, billingPeriod));
        
        lastPayment = block.timestamp - 15 days;
        assertFalse(helper.isPaymentDue(lastPayment, billingPeriod));
    }
}
