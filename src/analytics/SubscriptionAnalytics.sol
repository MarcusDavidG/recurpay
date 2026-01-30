// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionAnalytics {
    struct CreatorMetrics {
        uint256 totalSubscribers;
        uint256 activeSubscribers;
        uint256 totalRevenue;
        uint256 monthlyRevenue;
        uint256 averageSubscriptionLength;
        uint256 churnRate;
    }

    struct SubscriptionMetrics {
        uint256 totalSubscriptions;
        uint256 activeSubscriptions;
        uint256 cancelledSubscriptions;
        uint256 totalVolume;
        mapping(uint256 => uint256) monthlyVolume;
    }

    mapping(address => CreatorMetrics) public creatorMetrics;
    mapping(address => SubscriptionMetrics) public subscriptionMetrics;
    
    uint256 public totalPlatformRevenue;
    uint256 public totalActiveSubscriptions;

    event MetricsUpdated(address indexed creator, uint256 revenue, uint256 subscribers);

    function updateCreatorMetrics(
        address creator,
        uint256 revenue,
        bool isNewSubscriber,
        bool isCancellation
    ) external {
        CreatorMetrics storage metrics = creatorMetrics[creator];
        
        metrics.totalRevenue += revenue;
        metrics.monthlyRevenue += revenue;
        
        if (isNewSubscriber) {
            metrics.totalSubscribers++;
            metrics.activeSubscribers++;
        }
        
        if (isCancellation) {
            metrics.activeSubscribers--;
        }

        totalPlatformRevenue += revenue;
        
        emit MetricsUpdated(creator, revenue, metrics.activeSubscribers);
    }

    function updateSubscriptionMetrics(address creator, uint256 amount, bool isActive) external {
        SubscriptionMetrics storage metrics = subscriptionMetrics[creator];
        
        metrics.totalVolume += amount;
        metrics.monthlyVolume[getCurrentMonth()] += amount;
        
        if (isActive) {
            metrics.activeSubscriptions++;
            totalActiveSubscriptions++;
        }
    }

    function calculateChurnRate(address creator) external view returns (uint256) {
        CreatorMetrics memory metrics = creatorMetrics[creator];
        if (metrics.totalSubscribers == 0) return 0;
        
        uint256 churned = metrics.totalSubscribers - metrics.activeSubscribers;
        return (churned * 10000) / metrics.totalSubscribers;
    }

    function getCreatorMetrics(address creator) external view returns (CreatorMetrics memory) {
        return creatorMetrics[creator];
    }

    function getCurrentMonth() internal view returns (uint256) {
        return block.timestamp / 30 days;
    }

    function getMonthlyVolume(address creator, uint256 month) external view returns (uint256) {
        return subscriptionMetrics[creator].monthlyVolume[month];
    }
}
