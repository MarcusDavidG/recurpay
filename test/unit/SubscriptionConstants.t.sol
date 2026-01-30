// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/constants/SubscriptionConstants.sol";

contract SubscriptionConstantsTest is Test {
    SubscriptionConstants constants;

    function setUp() public {
        constants = new SubscriptionConstants();
    }

    function testTimeConstants() public {
        assertEq(constants.SECONDS_PER_DAY(), 86400);
        assertEq(constants.SECONDS_PER_WEEK(), 604800);
        assertEq(constants.SECONDS_PER_MONTH(), 2592000);
        assertEq(constants.SECONDS_PER_YEAR(), 31536000);
    }

    function testPercentageConstants() public {
        assertEq(constants.MAX_FEE_PERCENTAGE(), 1000); // 10%
        assertEq(constants.DEFAULT_LATE_FEE(), 500); // 5%
        assertEq(constants.MAX_DISCOUNT(), 5000); // 50%
        assertEq(constants.BASIS_POINTS(), 10000); // 100%
    }

    function testSubscriptionLimits() public {
        assertEq(constants.MIN_SUBSCRIPTION_PRICE(), 0.001 ether);
        assertEq(constants.MAX_SUBSCRIPTION_PRICE(), 1000 ether);
        assertEq(constants.MIN_BILLING_PERIOD(), 1 days);
        assertEq(constants.MAX_BILLING_PERIOD(), 365 days);
        assertEq(constants.DEFAULT_GRACE_PERIOD(), 3 days);
        assertEq(constants.MAX_GRACE_PERIOD(), 30 days);
    }

    function testSystemLimits() public {
        assertEq(constants.MAX_BATCH_SIZE(), 100);
        assertEq(constants.MAX_RETRY_ATTEMPTS(), 5);
        assertEq(constants.DEFAULT_TIMEOUT(), 1 hours);
    }

    function testStatusCodes() public {
        assertEq(constants.STATUS_ACTIVE(), 1);
        assertEq(constants.STATUS_PAUSED(), 2);
        assertEq(constants.STATUS_CANCELLED(), 3);
        assertEq(constants.STATUS_EXPIRED(), 4);
        assertEq(constants.STATUS_GRACE_PERIOD(), 5);
    }

    function testGetTimeConstant() public {
        assertEq(constants.getTimeConstant("DAY"), 86400);
        assertEq(constants.getTimeConstant("WEEK"), 604800);
        assertEq(constants.getTimeConstant("MONTH"), 2592000);
        assertEq(constants.getTimeConstant("YEAR"), 31536000);
        assertEq(constants.getTimeConstant("INVALID"), 0);
    }

    function testGetPercentageConstant() public {
        assertEq(constants.getPercentageConstant("MAX_FEE"), 1000);
        assertEq(constants.getPercentageConstant("LATE_FEE"), 500);
        assertEq(constants.getPercentageConstant("MAX_DISCOUNT"), 5000);
        assertEq(constants.getPercentageConstant("BASIS_POINTS"), 10000);
        assertEq(constants.getPercentageConstant("INVALID"), 0);
    }
}
