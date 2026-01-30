// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionHealthMonitor {
    enum HealthStatus {
        HEALTHY,
        AT_RISK,
        CRITICAL,
        FAILED
    }

    struct HealthMetrics {
        uint256 paymentSuccessRate;
        uint256 consecutiveFailures;
        uint256 lastSuccessfulPayment;
        uint256 averagePaymentDelay;
        uint256 totalPaymentAttempts;
        uint256 successfulPayments;
        HealthStatus status;
    }

    struct AlertConfig {
        uint256 maxConsecutiveFailures;
        uint256 minSuccessRate;
        uint256 maxPaymentDelay;
        bool alertsEnabled;
        address[] alertRecipients;
    }

    struct HealthAlert {
        bytes32 subscriptionId;
        HealthStatus severity;
        string message;
        uint256 triggeredAt;
        bool acknowledged;
        address acknowledgedBy;
    }

    mapping(bytes32 => HealthMetrics) public subscriptionHealth;
    mapping(address => AlertConfig) public alertConfigs;
    mapping(bytes32 => HealthAlert[]) public subscriptionAlerts;
    mapping(address => bytes32[]) public creatorSubscriptions;
    
    uint256 public alertCounter;

    event HealthStatusChanged(bytes32 indexed subscriptionId, HealthStatus oldStatus, HealthStatus newStatus);
    event AlertTriggered(bytes32 indexed subscriptionId, HealthStatus severity, string message);
    event AlertAcknowledged(bytes32 indexed subscriptionId, uint256 alertIndex, address acknowledgedBy);

    function updatePaymentResult(
        bytes32 subscriptionId,
        bool success,
        uint256 paymentDelay
    ) external {
        HealthMetrics storage health = subscriptionHealth[subscriptionId];
        
        health.totalPaymentAttempts++;
        
        if (success) {
            health.successfulPayments++;
            health.consecutiveFailures = 0;
            health.lastSuccessfulPayment = block.timestamp;
            
            // Update average payment delay
            health.averagePaymentDelay = (health.averagePaymentDelay + paymentDelay) / 2;
        } else {
            health.consecutiveFailures++;
        }
        
        // Calculate success rate
        health.paymentSuccessRate = (health.successfulPayments * 10000) / health.totalPaymentAttempts;
        
        // Update health status
        HealthStatus oldStatus = health.status;
        health.status = calculateHealthStatus(subscriptionId);
        
        if (oldStatus != health.status) {
            emit HealthStatusChanged(subscriptionId, oldStatus, health.status);
            
            // Trigger alert if status worsened
            if (health.status > oldStatus) {
                triggerHealthAlert(subscriptionId, health.status);
            }
        }
    }

    function calculateHealthStatus(bytes32 subscriptionId) internal view returns (HealthStatus) {
        HealthMetrics memory health = subscriptionHealth[subscriptionId];
        address creator = getCreatorFromSubscriptionId(subscriptionId);
        AlertConfig memory config = alertConfigs[creator];
        
        // Critical conditions
        if (health.consecutiveFailures >= config.maxConsecutiveFailures) {
            return HealthStatus.CRITICAL;
        }
        
        if (health.paymentSuccessRate < config.minSuccessRate) {
            return HealthStatus.CRITICAL;
        }
        
        // At risk conditions
        if (health.consecutiveFailures >= config.maxConsecutiveFailures / 2) {
            return HealthStatus.AT_RISK;
        }
        
        if (health.averagePaymentDelay > config.maxPaymentDelay) {
            return HealthStatus.AT_RISK;
        }
        
        if (block.timestamp - health.lastSuccessfulPayment > 45 days) {
            return HealthStatus.AT_RISK;
        }
        
        return HealthStatus.HEALTHY;
    }

    function triggerHealthAlert(bytes32 subscriptionId, HealthStatus severity) internal {
        address creator = getCreatorFromSubscriptionId(subscriptionId);
        AlertConfig memory config = alertConfigs[creator];
        
        if (!config.alertsEnabled) return;
        
        string memory message = getAlertMessage(severity);
        
        subscriptionAlerts[subscriptionId].push(HealthAlert({
            subscriptionId: subscriptionId,
            severity: severity,
            message: message,
            triggeredAt: block.timestamp,
            acknowledged: false,
            acknowledgedBy: address(0)
        }));
        
        emit AlertTriggered(subscriptionId, severity, message);
    }

    function getAlertMessage(HealthStatus severity) internal pure returns (string memory) {
        if (severity == HealthStatus.CRITICAL) {
            return "Subscription health is critical - immediate attention required";
        } else if (severity == HealthStatus.AT_RISK) {
            return "Subscription health is at risk - monitoring recommended";
        } else if (severity == HealthStatus.FAILED) {
            return "Subscription has failed - intervention required";
        }
        return "Subscription status updated";
    }

    function setAlertConfig(
        uint256 maxConsecutiveFailures,
        uint256 minSuccessRate,
        uint256 maxPaymentDelay,
        bool alertsEnabled,
        address[] memory alertRecipients
    ) external {
        alertConfigs[msg.sender] = AlertConfig({
            maxConsecutiveFailures: maxConsecutiveFailures,
            minSuccessRate: minSuccessRate,
            maxPaymentDelay: maxPaymentDelay,
            alertsEnabled: alertsEnabled,
            alertRecipients: alertRecipients
        });
    }

    function acknowledgeAlert(bytes32 subscriptionId, uint256 alertIndex) external {
        require(alertIndex < subscriptionAlerts[subscriptionId].length, "Invalid alert index");
        
        HealthAlert storage alert = subscriptionAlerts[subscriptionId][alertIndex];
        require(!alert.acknowledged, "Alert already acknowledged");
        
        address creator = getCreatorFromSubscriptionId(subscriptionId);
        require(msg.sender == creator, "Not authorized");
        
        alert.acknowledged = true;
        alert.acknowledgedBy = msg.sender;
        
        emit AlertAcknowledged(subscriptionId, alertIndex, msg.sender);
    }

    function getSubscriptionHealth(bytes32 subscriptionId) external view returns (HealthMetrics memory) {
        return subscriptionHealth[subscriptionId];
    }

    function getSubscriptionAlerts(bytes32 subscriptionId) external view returns (HealthAlert[] memory) {
        return subscriptionAlerts[subscriptionId];
    }

    function getUnacknowledgedAlerts(bytes32 subscriptionId) external view returns (HealthAlert[] memory unacked) {
        HealthAlert[] memory allAlerts = subscriptionAlerts[subscriptionId];
        uint256 unackedCount = 0;
        
        // Count unacknowledged alerts
        for (uint256 i = 0; i < allAlerts.length; i++) {
            if (!allAlerts[i].acknowledged) {
                unackedCount++;
            }
        }
        
        // Create array of unacknowledged alerts
        unacked = new HealthAlert[](unackedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allAlerts.length; i++) {
            if (!allAlerts[i].acknowledged) {
                unacked[index] = allAlerts[i];
                index++;
            }
        }
    }

    function getCreatorHealthOverview(address creator) external view returns (
        uint256 healthyCount,
        uint256 atRiskCount,
        uint256 criticalCount,
        uint256 failedCount
    ) {
        bytes32[] memory subscriptions = creatorSubscriptions[creator];
        
        for (uint256 i = 0; i < subscriptions.length; i++) {
            HealthStatus status = subscriptionHealth[subscriptions[i]].status;
            
            if (status == HealthStatus.HEALTHY) healthyCount++;
            else if (status == HealthStatus.AT_RISK) atRiskCount++;
            else if (status == HealthStatus.CRITICAL) criticalCount++;
            else if (status == HealthStatus.FAILED) failedCount++;
        }
    }

    function addSubscriptionToMonitoring(bytes32 subscriptionId, address creator) external {
        creatorSubscriptions[creator].push(subscriptionId);
        
        // Initialize health metrics
        subscriptionHealth[subscriptionId] = HealthMetrics({
            paymentSuccessRate: 10000, // Start at 100%
            consecutiveFailures: 0,
            lastSuccessfulPayment: block.timestamp,
            averagePaymentDelay: 0,
            totalPaymentAttempts: 0,
            successfulPayments: 0,
            status: HealthStatus.HEALTHY
        });
    }

    function getCreatorFromSubscriptionId(bytes32 subscriptionId) internal pure returns (address) {
        // Extract creator address from subscription ID
        return address(uint160(uint256(subscriptionId) >> 96));
    }

    function getAlertConfig(address creator) external view returns (AlertConfig memory) {
        return alertConfigs[creator];
    }

    function bulkAcknowledgeAlerts(bytes32 subscriptionId, uint256[] memory alertIndices) external {
        address creator = getCreatorFromSubscriptionId(subscriptionId);
        require(msg.sender == creator, "Not authorized");
        
        for (uint256 i = 0; i < alertIndices.length; i++) {
            uint256 alertIndex = alertIndices[i];
            if (alertIndex < subscriptionAlerts[subscriptionId].length) {
                HealthAlert storage alert = subscriptionAlerts[subscriptionId][alertIndex];
                if (!alert.acknowledged) {
                    alert.acknowledged = true;
                    alert.acknowledgedBy = msg.sender;
                    emit AlertAcknowledged(subscriptionId, alertIndex, msg.sender);
                }
            }
        }
    }
}
