// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionMock {
    mapping(uint256 => bool) public activePlans;
    mapping(address => uint256) public userSubscriptions;
    uint256 public planCounter;

    event MockPlanCreated(uint256 planId);
    event MockSubscriptionCreated(address user, uint256 planId);

    function createPlan() external returns (uint256) {
        uint256 planId = ++planCounter;
        activePlans[planId] = true;
        emit MockPlanCreated(planId);
        return planId;
    }

    function subscribe(uint256 planId) external {
        require(activePlans[planId], "Plan not active");
        userSubscriptions[msg.sender] = planId;
        emit MockSubscriptionCreated(msg.sender, planId);
    }

    function isSubscribed(address user) external view returns (bool) {
        return userSubscriptions[user] > 0;
    }

    function getUserPlan(address user) external view returns (uint256) {
        return userSubscriptions[user];
    }

    function deactivatePlan(uint256 planId) external {
        activePlans[planId] = false;
    }
}
