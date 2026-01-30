// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract EmergencyPause is Ownable, Pausable {
    struct EmergencyAction {
        string reason;
        uint256 timestamp;
        address initiator;
        bool resolved;
        string resolution;
    }

    mapping(uint256 => EmergencyAction) public emergencyActions;
    mapping(address => bool) public emergencyOperators;
    
    uint256 public emergencyActionCounter;
    uint256 public constant MAX_PAUSE_DURATION = 7 days;
    uint256 public pauseStartTime;

    event EmergencyPaused(uint256 indexed actionId, string reason, address indexed initiator);
    event EmergencyResolved(uint256 indexed actionId, string resolution);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    modifier onlyEmergencyOperator() {
        require(emergencyOperators[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    modifier whenNotPausedOrOwner() {
        require(!paused() || msg.sender == owner(), "Paused");
        _;
    }

    function addEmergencyOperator(address operator) external onlyOwner {
        emergencyOperators[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeEmergencyOperator(address operator) external onlyOwner {
        emergencyOperators[operator] = false;
        emit OperatorRemoved(operator);
    }

    function emergencyPause(string memory reason) external onlyEmergencyOperator {
        require(!paused(), "Already paused");
        
        uint256 actionId = ++emergencyActionCounter;
        
        emergencyActions[actionId] = EmergencyAction({
            reason: reason,
            timestamp: block.timestamp,
            initiator: msg.sender,
            resolved: false,
            resolution: ""
        });

        pauseStartTime = block.timestamp;
        _pause();

        emit EmergencyPaused(actionId, reason, msg.sender);
    }

    function resolveEmergency(
        uint256 actionId,
        string memory resolution
    ) external onlyOwner {
        require(paused(), "Not paused");
        require(!emergencyActions[actionId].resolved, "Already resolved");

        emergencyActions[actionId].resolved = true;
        emergencyActions[actionId].resolution = resolution;

        _unpause();

        emit EmergencyResolved(actionId, resolution);
    }

    function forceUnpause() external onlyOwner {
        require(paused(), "Not paused");
        require(
            block.timestamp >= pauseStartTime + MAX_PAUSE_DURATION,
            "Max pause duration not reached"
        );

        _unpause();
    }

    function getEmergencyAction(uint256 actionId) external view returns (EmergencyAction memory) {
        return emergencyActions[actionId];
    }

    function isPausedByEmergency() external view returns (bool) {
        return paused();
    }

    function getRemainingPauseTime() external view returns (uint256) {
        if (!paused()) return 0;
        
        uint256 elapsed = block.timestamp - pauseStartTime;
        if (elapsed >= MAX_PAUSE_DURATION) return 0;
        
        return MAX_PAUSE_DURATION - elapsed;
    }

    // Override pause functions to include emergency logic
    function pause() public override onlyOwner {
        pauseStartTime = block.timestamp;
        super.pause();
    }

    function unpause() public override onlyOwner {
        super.unpause();
    }
}
