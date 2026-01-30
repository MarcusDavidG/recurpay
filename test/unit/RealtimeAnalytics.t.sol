// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/analytics/RealtimeAnalytics.sol";

contract RealtimeAnalyticsTest is Test {
    RealtimeAnalytics analytics;
    address creator = address(0x1);

    function setUp() public {
        analytics = new RealtimeAnalytics();
    }

    function testTakeSnapshot() public {
        vm.prank(creator);
        analytics.takeSnapshot(creator, 100, 1000, 10, 5);

        RealtimeAnalytics.MetricSnapshot memory snapshot = analytics.getLatestSnapshot(creator);
        assertEq(snapshot.activeSubscriptions, 100);
        assertEq(snapshot.revenue, 1000);
        assertEq(snapshot.newSignups, 10);
        assertEq(snapshot.churnCount, 5);
    }

    function testSnapshotInterval() public {
        vm.prank(creator);
        analytics.takeSnapshot(creator, 100, 1000, 10, 5);

        vm.expectRevert("Too early for snapshot");
        analytics.takeSnapshot(creator, 110, 1100, 12, 3);

        vm.warp(block.timestamp + 1 hours + 1);
        analytics.takeSnapshot(creator, 110, 1100, 12, 3);

        RealtimeAnalytics.MetricSnapshot memory snapshot = analytics.getLatestSnapshot(creator);
        assertEq(snapshot.activeSubscriptions, 110);
    }

    function testGrowthRateCalculation() public {
        // Take initial snapshot
        analytics.takeSnapshot(creator, 100, 1000, 10, 5);
        
        vm.warp(block.timestamp + 1 hours + 1);
        analytics.takeSnapshot(creator, 120, 1200, 15, 3);

        int256 growthRate = analytics.getGrowthRate(creator, 1);
        assertEq(growthRate, 2000); // 20% growth
    }

    function testMultipleSnapshots() public {
        for (uint256 i = 0; i < 5; i++) {
            analytics.takeSnapshot(creator, 100 + i * 10, 1000 + i * 100, 10 + i, 5);
            vm.warp(block.timestamp + 1 hours + 1);
        }

        RealtimeAnalytics.MetricSnapshot memory snapshot = analytics.getLatestSnapshot(creator);
        assertEq(snapshot.activeSubscriptions, 140);
        assertEq(snapshot.revenue, 1400);
    }
}
