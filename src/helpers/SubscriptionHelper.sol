// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionHelper {
    function calculateProRatedAmount(
        uint256 fullAmount,
        uint256 totalDays,
        uint256 remainingDays
    ) external pure returns (uint256) {
        return (fullAmount * remainingDays) / totalDays;
    }

    function calculateNextBillingDate(
        uint256 lastBilling,
        uint256 billingPeriod
    ) external pure returns (uint256) {
        return lastBilling + billingPeriod;
    }

    function isSubscriptionActive(
        uint256 lastPayment,
        uint256 billingPeriod,
        uint256 gracePeriod
    ) external view returns (bool) {
        return block.timestamp <= lastPayment + billingPeriod + gracePeriod;
    }

    function calculateLateFee(
        uint256 amount,
        uint256 daysLate,
        uint256 lateFeeRate
    ) external pure returns (uint256) {
        return (amount * lateFeeRate * daysLate) / (10000 * 30);
    }

    function generateSubscriptionId(
        address creator,
        address subscriber,
        uint256 planId
    ) external view returns (bytes32) {
        return keccak256(abi.encodePacked(creator, subscriber, planId, block.timestamp));
    }

    function validateSubscriptionData(
        uint256 price,
        uint256 duration,
        address token
    ) external pure returns (bool) {
        return price > 0 && duration > 0 && token != address(0);
    }

    function calculateDiscount(
        uint256 originalPrice,
        uint256 discountPercent
    ) external pure returns (uint256) {
        return originalPrice - (originalPrice * discountPercent / 10000);
    }

    function isPaymentDue(
        uint256 lastPayment,
        uint256 billingPeriod
    ) external view returns (bool) {
        return block.timestamp >= lastPayment + billingPeriod;
    }
}
