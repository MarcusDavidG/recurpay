// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/metrics/SubscriptionMetrics.sol";

contract SubscriptionMetricsTest is Test {
    SubscriptionMetrics metrics;

    function setUp() public {
        metrics = new SubscriptionMetrics();
    }

    function testUpdateMetric() public {
        metrics.updateMetric("activeUsers", 100);
        assertEq(metrics.getMetric("activeUsers"), 100);
    }

    function testHistoricalData() public {
        metrics.updateMetric("revenue", 1000);
        metrics.updateMetric("revenue", 1500);
        metrics.updateMetric("revenue", 2000);

        uint256[] memory history = metrics.getHistoricalData("revenue");
        assertEq(history.length, 3);
        assertEq(history[0], 1000);
        assertEq(history[1], 1500);
        assertEq(history[2], 2000);
    }
}
