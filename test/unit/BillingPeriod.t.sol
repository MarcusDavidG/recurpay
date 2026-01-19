// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BillingPeriod} from "src/libraries/BillingPeriod.sol";

contract BillingPeriodTest is Test {
    function test_CalculatePeriodEnd() public pure {
        uint64 start = 1000;
        uint32 period = 30 days;

        uint64 end = BillingPeriod.calculatePeriodEnd(start, period);

        assertEq(end, start + period);
    }

    function test_PeriodsSince_Zero() public pure {
        uint64 start = 1000;
        uint64 current = 1000;
        uint32 period = 30 days;

        uint32 periods = BillingPeriod.periodsSince(start, current, period);

        assertEq(periods, 0);
    }

    function test_PeriodsSince_One() public pure {
        uint64 start = 1000;
        uint32 period = 30 days;
        uint64 current = start + period + 1;

        uint32 periods = BillingPeriod.periodsSince(start, current, period);

        assertEq(periods, 1);
    }

    function test_PeriodsSince_Multiple() public pure {
        uint64 start = 1000;
        uint32 period = 30 days;
        uint64 current = start + (period * 5) + 1;

        uint32 periods = BillingPeriod.periodsSince(start, current, period);

        assertEq(periods, 5);
    }

    function test_IsPaymentDue_False() public pure {
        uint64 nextDue = 1000;
        uint64 current = 500;

        bool isDue = BillingPeriod.isPaymentDue(nextDue, current);

        assertFalse(isDue);
    }

    function test_IsPaymentDue_True() public pure {
        uint64 nextDue = 1000;
        uint64 current = 1000;

        bool isDue = BillingPeriod.isPaymentDue(nextDue, current);

        assertTrue(isDue);
    }

    function test_IsInGracePeriod_False_BeforePeriodEnd() public pure {
        uint64 periodEnd = 1000;
        uint32 gracePeriod = 3 days;
        uint64 current = 500;

        bool inGrace = BillingPeriod.isInGracePeriod(periodEnd, gracePeriod, current);

        assertFalse(inGrace);
    }

    function test_IsInGracePeriod_True() public pure {
        uint64 periodEnd = 1000;
        uint32 gracePeriod = 3 days;
        uint64 current = periodEnd + 1 days;

        bool inGrace = BillingPeriod.isInGracePeriod(periodEnd, gracePeriod, current);

        assertTrue(inGrace);
    }

    function test_IsGracePeriodExpired() public pure {
        uint64 periodEnd = 1000;
        uint32 gracePeriod = 3 days;
        uint64 current = periodEnd + gracePeriod + 1;

        bool expired = BillingPeriod.isGracePeriodExpired(periodEnd, gracePeriod, current);

        assertTrue(expired);
    }

    function test_IsValidBillingPeriod_Valid() public pure {
        assertTrue(BillingPeriod.isValidBillingPeriod(30 days));
        assertTrue(BillingPeriod.isValidBillingPeriod(7 days));
        assertTrue(BillingPeriod.isValidBillingPeriod(365 days));
    }

    function test_IsValidBillingPeriod_Invalid() public pure {
        assertFalse(BillingPeriod.isValidBillingPeriod(30 minutes)); // Too short
        assertFalse(BillingPeriod.isValidBillingPeriod(800 days)); // Too long
    }

    function test_CalculateProrata() public pure {
        uint256 fullAmount = 100 ether;
        uint32 periodDuration = 30 days;
        uint32 remainingTime = 15 days;

        uint256 prorated = BillingPeriod.calculateProrata(fullAmount, periodDuration, remainingTime);

        assertEq(prorated, 50 ether);
    }
}
