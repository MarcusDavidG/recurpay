// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MetricsAggregator {
    struct AggregatedMetric {
        uint256 sum;
        uint256 count;
        uint256 min;
        uint256 max;
        uint256 lastUpdate;
    }

    mapping(string => AggregatedMetric) public metrics;
    mapping(string => mapping(uint256 => uint256)) public timeSeriesData;
    
    string[] public metricNames;

    event MetricAggregated(string indexed metricName, uint256 value, uint256 timestamp);

    function addMetric(string memory metricName, uint256 value) external {
        AggregatedMetric storage metric = metrics[metricName];
        
        if (metric.count == 0) {
            metric.min = value;
            metric.max = value;
            metricNames.push(metricName);
        } else {
            if (value < metric.min) metric.min = value;
            if (value > metric.max) metric.max = value;
        }

        metric.sum += value;
        metric.count++;
        metric.lastUpdate = block.timestamp;

        // Store time series data (daily buckets)
        uint256 dayBucket = block.timestamp / 1 days;
        timeSeriesData[metricName][dayBucket] += value;

        emit MetricAggregated(metricName, value, block.timestamp);
    }

    function getAverage(string memory metricName) external view returns (uint256) {
        AggregatedMetric memory metric = metrics[metricName];
        return metric.count > 0 ? metric.sum / metric.count : 0;
    }

    function getMetricSummary(string memory metricName) external view returns (
        uint256 sum,
        uint256 count,
        uint256 min,
        uint256 max,
        uint256 average
    ) {
        AggregatedMetric memory metric = metrics[metricName];
        return (
            metric.sum,
            metric.count,
            metric.min,
            metric.max,
            metric.count > 0 ? metric.sum / metric.count : 0
        );
    }

    function getTimeSeriesData(string memory metricName, uint256 fromDay, uint256 toDay) 
        external 
        view 
        returns (uint256[] memory values) 
    {
        require(toDay >= fromDay, "Invalid range");
        
        uint256 length = toDay - fromDay + 1;
        values = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            values[i] = timeSeriesData[metricName][fromDay + i];
        }
    }

    function getAllMetricNames() external view returns (string[] memory) {
        return metricNames;
    }

    function resetMetric(string memory metricName) external {
        delete metrics[metricName];
    }
}
