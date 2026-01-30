// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/alerts/SubscriptionAlerts.sol";

contract SubscriptionAlertsTest is Test {
    SubscriptionAlerts alerts;
    address user = address(0x1);

    function setUp() public {
        alerts = new SubscriptionAlerts();
    }

    function testCreateAlert() public {
        alerts.createAlert(user, "Payment due", 1);
        
        (string memory message, uint256 severity, uint256 timestamp, bool acknowledged) = alerts.userAlerts(user, 0);
        assertEq(message, "Payment due");
        assertEq(severity, 1);
        assertFalse(acknowledged);
    }

    function testAcknowledgeAlert() public {
        alerts.createAlert(user, "Payment due", 1);
        
        vm.prank(user);
        alerts.acknowledgeAlert(0);
        
        (, , , bool acknowledged) = alerts.userAlerts(user, 0);
        assertTrue(acknowledged);
    }
}
