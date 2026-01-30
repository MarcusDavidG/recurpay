// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RealtimeAnalytics {
    struct MetricSnapshot {
        uint256 timestamp;
        uint256 activeSubscriptions;
        uint256 revenue;
        uint256 newSignups;
        uint256 churnCount;
    }

    mapping(address => MetricSnapshot[]) public creatorSnapshots;
    mapping(address => uint256) public lastSnapshotTime;
    
    uint256 public constant SNAPSHOT_INTERVAL = 1 hours;

    event SnapshotTaken(address indexed creator, uint256 timestamp);

    function takeSnapshot(
        address creator,
        uint256 activeSubscriptions,
        uint256 revenue,
        uint256 newSignups,
        uint256 churnCount
    ) external {
        require(
            block.timestamp >= lastSnapshotTime[creator] + SNAPSHOT_INTERVAL,
            "Too early for snapshot"
        );

        creatorSnapshots[creator].push(MetricSnapshot({
            timestamp: block.timestamp,
            activeSubscriptions: activeSubscriptions,
            revenue: revenue,
            newSignups: newSignups,
            churnCount: churnCount
        }));

        lastSnapshotTime[creator] = block.timestamp;
        emit SnapshotTaken(creator, block.timestamp);
    }

    function getLatestSnapshot(address creator) external view returns (MetricSnapshot memory) {
        MetricSnapshot[] memory snapshots = creatorSnapshots[creator];
        require(snapshots.length > 0, "No snapshots");
        return snapshots[snapshots.length - 1];
    }

    function getGrowthRate(address creator, uint256 hours) external view returns (int256) {
        MetricSnapshot[] memory snapshots = creatorSnapshots[creator];
        require(snapshots.length >= 2, "Insufficient data");

        uint256 targetTime = block.timestamp - (hours * 1 hours);
        uint256 currentSubs = snapshots[snapshots.length - 1].activeSubscriptions;
        
        for (uint256 i = snapshots.length - 1; i > 0; i--) {
            if (snapshots[i].timestamp <= targetTime) {
                uint256 pastSubs = snapshots[i].activeSubscriptions;
                if (pastSubs == 0) return 0;
                return int256((currentSubs * 10000) / pastSubs) - 10000;
            }
        }
        return 0;
    }
}
