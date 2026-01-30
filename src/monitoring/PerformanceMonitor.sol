// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PerformanceMonitor {
    struct PerformanceMetrics {
        uint256 avgResponseTime;
        uint256 successRate;
        uint256 errorCount;
        uint256 throughput;
        uint256 lastUpdate;
    }

    mapping(string => PerformanceMetrics) public serviceMetrics;
    mapping(string => uint256[]) public responseTimeHistory;
    
    string[] public monitoredServices;

    event MetricsUpdated(string indexed service, uint256 responseTime, bool success);
    event AlertTriggered(string indexed service, string alertType, uint256 value);

    function addService(string memory serviceName) external {
        serviceMetrics[serviceName] = PerformanceMetrics({
            avgResponseTime: 0,
            successRate: 10000,
            errorCount: 0,
            throughput: 0,
            lastUpdate: block.timestamp
        });
        monitoredServices.push(serviceName);
    }

    function recordMetric(
        string memory serviceName,
        uint256 responseTime,
        bool success
    ) external {
        PerformanceMetrics storage metrics = serviceMetrics[serviceName];
        
        // Update response time
        responseTimeHistory[serviceName].push(responseTime);
        if (responseTimeHistory[serviceName].length > 100) {
            // Keep only last 100 entries
            for (uint256 i = 0; i < 99; i++) {
                responseTimeHistory[serviceName][i] = responseTimeHistory[serviceName][i + 1];
            }
            responseTimeHistory[serviceName].pop();
        }

        // Calculate average response time
        uint256 total = 0;
        for (uint256 i = 0; i < responseTimeHistory[serviceName].length; i++) {
            total += responseTimeHistory[serviceName][i];
        }
        metrics.avgResponseTime = total / responseTimeHistory[serviceName].length;

        // Update success rate
        if (!success) {
            metrics.errorCount++;
        }

        metrics.lastUpdate = block.timestamp;
        emit MetricsUpdated(serviceName, responseTime, success);

        // Check for alerts
        if (responseTime > 5000) { // 5 seconds
            emit AlertTriggered(serviceName, "HIGH_RESPONSE_TIME", responseTime);
        }
    }

    function getServiceMetrics(string memory serviceName) external view returns (PerformanceMetrics memory) {
        return serviceMetrics[serviceName];
    }

    function getMonitoredServices() external view returns (string[] memory) {
        return monitoredServices;
    }
}
