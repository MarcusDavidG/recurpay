// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionFactory2 {
    struct Plan {
        address creator;
        uint256 price;
        uint256 duration;
        bool active;
    }

    mapping(uint256 => Plan) public plans;
    uint256 public planCounter;

    event PlanCreated(uint256 indexed planId, address creator);

    function createPlan(uint256 price, uint256 duration) external returns (uint256) {
        uint256 planId = ++planCounter;
        plans[planId] = Plan(msg.sender, price, duration, true);
        emit PlanCreated(planId, msg.sender);
        return planId;
    }

    function deactivatePlan(uint256 planId) external {
        require(plans[planId].creator == msg.sender, "Not creator");
        plans[planId].active = false;
    }
}
