// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AnalyticsDashboard {
    struct DashboardMetrics {
        uint256 totalRevenue;
        uint256 monthlyRevenue;
        uint256 activeSubscribers;
        uint256 newSubscribers;
        uint256 churnedSubscribers;
        uint256 averageRevenuePerUser;
        uint256 lifetimeValue;
        uint256 conversionRate;
    }

    struct TimeSeriesData {
        uint256 timestamp;
        uint256 value;
        string metricType;
    }

    struct SubscriberSegment {
        string segmentName;
        uint256 subscriberCount;
        uint256 revenue;
        uint256 averageSpend;
        string[] characteristics;
    }

    mapping(address => DashboardMetrics) public creatorMetrics;
    mapping(address => mapping(uint256 => TimeSeriesData[])) public timeSeriesMetrics;
    mapping(address => SubscriberSegment[]) public subscriberSegments;
    mapping(address => mapping(string => uint256)) public customMetrics;
    
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_MONTH = 2592000;

    event MetricsUpdated(address indexed creator, string metricType, uint256 value);
    event SegmentCreated(address indexed creator, string segmentName, uint256 subscriberCount);

    function updateMetrics(
        address creator,
        uint256 revenue,
        uint256 activeSubscribers,
        uint256 newSubscribers,
        uint256 churnedSubscribers
    ) external {
        DashboardMetrics storage metrics = creatorMetrics[creator];
        
        metrics.totalRevenue += revenue;
        metrics.monthlyRevenue += revenue;
        metrics.activeSubscribers = activeSubscribers;
        metrics.newSubscribers += newSubscribers;
        metrics.churnedSubscribers += churnedSubscribers;
        
        if (activeSubscribers > 0) {
            metrics.averageRevenuePerUser = metrics.totalRevenue / activeSubscribers;
        }
        
        // Calculate conversion rate (simplified)
        if (metrics.newSubscribers > 0) {
            metrics.conversionRate = (metrics.activeSubscribers * 10000) / metrics.newSubscribers;
        }

        emit MetricsUpdated(creator, "revenue", revenue);
        emit MetricsUpdated(creator, "subscribers", activeSubscribers);
    }

    function addTimeSeriesData(
        address creator,
        string memory metricType,
        uint256 value
    ) external {
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        
        timeSeriesMetrics[creator][currentDay].push(TimeSeriesData({
            timestamp: block.timestamp,
            value: value,
            metricType: metricType
        }));

        emit MetricsUpdated(creator, metricType, value);
    }

    function createSubscriberSegment(
        string memory segmentName,
        uint256 subscriberCount,
        uint256 revenue,
        string[] memory characteristics
    ) external {
        subscriberSegments[msg.sender].push(SubscriberSegment({
            segmentName: segmentName,
            subscriberCount: subscriberCount,
            revenue: revenue,
            averageSpend: subscriberCount > 0 ? revenue / subscriberCount : 0,
            characteristics: characteristics
        }));

        emit SegmentCreated(msg.sender, segmentName, subscriberCount);
    }

    function setCustomMetric(string memory metricName, uint256 value) external {
        customMetrics[msg.sender][metricName] = value;
        emit MetricsUpdated(msg.sender, metricName, value);
    }

    function getCreatorMetrics(address creator) external view returns (DashboardMetrics memory) {
        return creatorMetrics[creator];
    }

    function getTimeSeriesData(
        address creator,
        uint256 startDay,
        uint256 endDay
    ) external view returns (TimeSeriesData[] memory data) {
        require(endDay >= startDay, "Invalid date range");
        
        uint256 totalDataPoints = 0;
        
        // Count total data points
        for (uint256 day = startDay; day <= endDay; day++) {
            totalDataPoints += timeSeriesMetrics[creator][day].length;
        }
        
        // Collect all data points
        data = new TimeSeriesData[](totalDataPoints);
        uint256 index = 0;
        
        for (uint256 day = startDay; day <= endDay; day++) {
            TimeSeriesData[] memory dayData = timeSeriesMetrics[creator][day];
            for (uint256 i = 0; i < dayData.length; i++) {
                data[index] = dayData[i];
                index++;
            }
        }
    }

    function getSubscriberSegments(address creator) external view returns (SubscriberSegment[] memory) {
        return subscriberSegments[creator];
    }

    function getCustomMetric(address creator, string memory metricName) external view returns (uint256) {
        return customMetrics[creator][metricName];
    }

    function calculateGrowthRate(address creator, uint256 days) external view returns (int256) {
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        uint256 pastDay = currentDay - days;
        
        uint256 currentValue = getCurrentDayMetric(creator, currentDay, "subscribers");
        uint256 pastValue = getCurrentDayMetric(creator, pastDay, "subscribers");
        
        if (pastValue == 0) return 0;
        
        return int256((currentValue * 10000) / pastValue) - 10000; // Return as basis points
    }

    function getCurrentDayMetric(
        address creator,
        uint256 day,
        string memory metricType
    ) internal view returns (uint256) {
        TimeSeriesData[] memory dayData = timeSeriesMetrics[creator][day];
        
        for (uint256 i = dayData.length; i > 0; i--) {
            if (keccak256(bytes(dayData[i-1].metricType)) == keccak256(bytes(metricType))) {
                return dayData[i-1].value;
            }
        }
        
        return 0;
    }

    function getMonthlyRecurringRevenue(address creator) external view returns (uint256) {
        return creatorMetrics[creator].monthlyRevenue;
    }

    function getChurnRate(address creator) external view returns (uint256) {
        DashboardMetrics memory metrics = creatorMetrics[creator];
        if (metrics.activeSubscribers + metrics.churnedSubscribers == 0) return 0;
        
        return (metrics.churnedSubscribers * 10000) / (metrics.activeSubscribers + metrics.churnedSubscribers);
    }

    function getLifetimeValue(address creator) external view returns (uint256) {
        DashboardMetrics memory metrics = creatorMetrics[creator];
        uint256 churnRate = getChurnRate(creator);
        
        if (churnRate == 0) return 0;
        
        // Simplified LTV calculation: ARPU / Churn Rate
        return (metrics.averageRevenuePerUser * 10000) / churnRate;
    }

    function resetMonthlyMetrics(address creator) external {
        // This would be called monthly to reset monthly metrics
        creatorMetrics[creator].monthlyRevenue = 0;
        creatorMetrics[creator].newSubscribers = 0;
        creatorMetrics[creator].churnedSubscribers = 0;
    }

    function getTopPerformingSegments(address creator, uint256 limit) external view returns (SubscriberSegment[] memory) {
        SubscriberSegment[] memory allSegments = subscriberSegments[creator];
        
        if (allSegments.length <= limit) {
            return allSegments;
        }
        
        // Simple selection of top segments by revenue (would implement proper sorting)
        SubscriberSegment[] memory topSegments = new SubscriberSegment[](limit);
        for (uint256 i = 0; i < limit && i < allSegments.length; i++) {
            topSegments[i] = allSegments[i];
        }
        
        return topSegments;
    }
}
