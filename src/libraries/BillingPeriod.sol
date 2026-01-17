// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BillingPeriod
/// @author RecurPay Protocol
/// @notice Library for billing period calculations and time utilities
library BillingPeriod {
    // =========================================================================
    // Constants - Common Billing Periods
    // =========================================================================

    /// @notice One day in seconds
    uint32 public constant ONE_DAY = 1 days;

    /// @notice One week in seconds
    uint32 public constant ONE_WEEK = 7 days;

    /// @notice One month in seconds (30 days approximation)
    uint32 public constant ONE_MONTH = 30 days;

    /// @notice One quarter in seconds (90 days)
    uint32 public constant ONE_QUARTER = 90 days;

    /// @notice One year in seconds (365 days)
    uint32 public constant ONE_YEAR = 365 days;

    /// @notice Minimum billing period (1 hour)
    uint32 public constant MIN_BILLING_PERIOD = 1 hours;

    /// @notice Maximum billing period (2 years)
    uint32 public constant MAX_BILLING_PERIOD = 730 days;

    /// @notice Minimum grace period (1 hour)
    uint32 public constant MIN_GRACE_PERIOD = 1 hours;

    /// @notice Maximum grace period (30 days)
    uint32 public constant MAX_GRACE_PERIOD = 30 days;

    /// @notice Default grace period (3 days)
    uint32 public constant DEFAULT_GRACE_PERIOD = 3 days;

    // =========================================================================
    // Period Calculation Functions
    // =========================================================================

    /// @notice Calculates the end timestamp of a billing period
    /// @param startTimestamp Start of the period
    /// @param billingPeriod Duration of the period in seconds
    /// @return endTimestamp End of the period
    function calculatePeriodEnd(
        uint64 startTimestamp,
        uint32 billingPeriod
    ) internal pure returns (uint64 endTimestamp) {
        unchecked {
            endTimestamp = startTimestamp + billingPeriod;
        }
    }

    /// @notice Calculates how many periods have passed since start
    /// @param startTimestamp Start timestamp
    /// @param currentTimestamp Current timestamp
    /// @param billingPeriod Duration of each period
    /// @return periods Number of complete periods elapsed
    function periodsSince(
        uint64 startTimestamp,
        uint64 currentTimestamp,
        uint32 billingPeriod
    ) internal pure returns (uint32 periods) {
        if (currentTimestamp <= startTimestamp) {
            return 0;
        }
        unchecked {
            periods = uint32((currentTimestamp - startTimestamp) / billingPeriod);
        }
    }

    /// @notice Calculates the start of the current billing period
    /// @param subscriptionStart Original subscription start
    /// @param currentTimestamp Current timestamp
    /// @param billingPeriod Duration of each period
    /// @return periodStart Start of current period
    function currentPeriodStart(
        uint64 subscriptionStart,
        uint64 currentTimestamp,
        uint32 billingPeriod
    ) internal pure returns (uint64 periodStart) {
        uint32 periods = periodsSince(subscriptionStart, currentTimestamp, billingPeriod);
        unchecked {
            periodStart = subscriptionStart + (periods * billingPeriod);
        }
    }

    /// @notice Calculates next payment due date
    /// @param lastPayment Last payment timestamp
    /// @param billingPeriod Duration of billing period
    /// @return nextDue Next payment due timestamp
    function nextPaymentDue(
        uint64 lastPayment,
        uint32 billingPeriod
    ) internal pure returns (uint64 nextDue) {
        unchecked {
            nextDue = lastPayment + billingPeriod;
        }
    }

    /// @notice Checks if payment is currently due
    /// @param nextDue Next payment due timestamp
    /// @param currentTimestamp Current timestamp
    /// @return isDue Whether payment is due
    function isPaymentDue(
        uint64 nextDue,
        uint64 currentTimestamp
    ) internal pure returns (bool isDue) {
        return currentTimestamp >= nextDue;
    }

    /// @notice Checks if subscription is in grace period
    /// @param periodEnd End of billing period
    /// @param gracePeriod Grace period duration
    /// @param currentTimestamp Current timestamp
    /// @return inGrace Whether in grace period
    function isInGracePeriod(
        uint64 periodEnd,
        uint32 gracePeriod,
        uint64 currentTimestamp
    ) internal pure returns (bool inGrace) {
        if (currentTimestamp <= periodEnd) {
            return false;
        }
        unchecked {
            return currentTimestamp <= (periodEnd + gracePeriod);
        }
    }

    /// @notice Checks if grace period has expired
    /// @param periodEnd End of billing period
    /// @param gracePeriod Grace period duration
    /// @param currentTimestamp Current timestamp
    /// @return expired Whether grace period expired
    function isGracePeriodExpired(
        uint64 periodEnd,
        uint32 gracePeriod,
        uint64 currentTimestamp
    ) internal pure returns (bool expired) {
        unchecked {
            return currentTimestamp > (periodEnd + gracePeriod);
        }
    }

    /// @notice Calculates prorated amount for partial period
    /// @param fullAmount Full period amount
    /// @param periodDuration Full period duration
    /// @param remainingTime Remaining time in period
    /// @return proratedAmount Prorated amount
    function calculateProrata(
        uint256 fullAmount,
        uint32 periodDuration,
        uint32 remainingTime
    ) internal pure returns (uint256 proratedAmount) {
        if (remainingTime >= periodDuration) {
            return fullAmount;
        }
        if (remainingTime == 0) {
            return 0;
        }
        proratedAmount = (fullAmount * remainingTime) / periodDuration;
    }

    // =========================================================================
    // Validation Functions
    // =========================================================================

    /// @notice Validates billing period is within acceptable range
    /// @param billingPeriod Period to validate
    /// @return valid Whether period is valid
    function isValidBillingPeriod(uint32 billingPeriod) internal pure returns (bool valid) {
        return billingPeriod >= MIN_BILLING_PERIOD && billingPeriod <= MAX_BILLING_PERIOD;
    }

    /// @notice Validates grace period is within acceptable range
    /// @param gracePeriod Period to validate
    /// @return valid Whether grace period is valid
    function isValidGracePeriod(uint32 gracePeriod) internal pure returns (bool valid) {
        return gracePeriod >= MIN_GRACE_PERIOD && gracePeriod <= MAX_GRACE_PERIOD;
    }

    /// @notice Returns human-readable period type
    /// @param billingPeriod Period in seconds
    /// @return periodType Period type string
    function getPeriodType(uint32 billingPeriod) internal pure returns (string memory periodType) {
        if (billingPeriod <= ONE_DAY) {
            return "daily";
        } else if (billingPeriod <= ONE_WEEK) {
            return "weekly";
        } else if (billingPeriod <= ONE_MONTH) {
            return "monthly";
        } else if (billingPeriod <= ONE_QUARTER) {
            return "quarterly";
        } else {
            return "annual";
        }
    }
}
