// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TrialManager {
    struct TrialConfig {
        uint256 duration;
        bool requiresPaymentMethod;
        uint256 maxTrialsPerUser;
        bool autoConvert;
        uint256 conversionPrice;
    }

    struct Trial {
        bytes32 subscriptionId;
        address subscriber;
        address creator;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool converted;
        bool cancelled;
        string cancellationReason;
    }

    mapping(address => TrialConfig) public trialConfigs;
    mapping(bytes32 => Trial) public trials;
    mapping(address => mapping(address => uint256)) public userTrialCount;
    
    uint256 public trialCounter;

    event TrialStarted(bytes32 indexed trialId, address indexed subscriber, address indexed creator);
    event TrialConverted(bytes32 indexed trialId, address indexed subscriber);
    event TrialCancelled(bytes32 indexed trialId, address indexed subscriber, string reason);
    event TrialExpired(bytes32 indexed trialId, address indexed subscriber);

    function setTrialConfig(
        uint256 duration,
        bool requiresPaymentMethod,
        uint256 maxTrialsPerUser,
        bool autoConvert,
        uint256 conversionPrice
    ) external {
        trialConfigs[msg.sender] = TrialConfig({
            duration: duration,
            requiresPaymentMethod: requiresPaymentMethod,
            maxTrialsPerUser: maxTrialsPerUser,
            autoConvert: autoConvert,
            conversionPrice: conversionPrice
        });
    }

    function startTrial(address creator) external returns (bytes32 trialId) {
        TrialConfig memory config = trialConfigs[creator];
        require(config.duration > 0, "Trials not enabled");
        require(
            userTrialCount[msg.sender][creator] < config.maxTrialsPerUser,
            "Trial limit exceeded"
        );

        trialId = keccak256(abi.encodePacked(
            msg.sender,
            creator,
            block.timestamp,
            trialCounter++
        ));

        trials[trialId] = Trial({
            subscriptionId: trialId, // Using trialId as subscriptionId for simplicity
            subscriber: msg.sender,
            creator: creator,
            startTime: block.timestamp,
            endTime: block.timestamp + config.duration,
            active: true,
            converted: false,
            cancelled: false,
            cancellationReason: ""
        });

        userTrialCount[msg.sender][creator]++;

        emit TrialStarted(trialId, msg.sender, creator);
    }

    function convertTrial(bytes32 trialId) external payable {
        Trial storage trial = trials[trialId];
        require(trial.subscriber == msg.sender, "Not your trial");
        require(trial.active, "Trial not active");
        require(!trial.converted, "Already converted");

        TrialConfig memory config = trialConfigs[trial.creator];
        require(msg.value >= config.conversionPrice, "Insufficient payment");

        trial.converted = true;
        trial.active = false;

        // Transfer payment to creator
        (bool success, ) = payable(trial.creator).call{value: msg.value}("");
        require(success, "Payment failed");

        emit TrialConverted(trialId, msg.sender);
    }

    function cancelTrial(bytes32 trialId, string memory reason) external {
        Trial storage trial = trials[trialId];
        require(trial.subscriber == msg.sender, "Not your trial");
        require(trial.active, "Trial not active");

        trial.active = false;
        trial.cancelled = true;
        trial.cancellationReason = reason;

        emit TrialCancelled(trialId, msg.sender, reason);
    }

    function checkTrialExpiration(bytes32 trialId) external {
        Trial storage trial = trials[trialId];
        require(trial.active, "Trial not active");
        require(block.timestamp >= trial.endTime, "Trial not expired");

        TrialConfig memory config = trialConfigs[trial.creator];
        
        if (config.autoConvert && !trial.converted) {
            // Auto-convert if payment method is available (simplified)
            trial.converted = true;
            emit TrialConverted(trialId, trial.subscriber);
        } else {
            trial.active = false;
            emit TrialExpired(trialId, trial.subscriber);
        }
    }

    function isTrialActive(bytes32 trialId) external view returns (bool) {
        Trial memory trial = trials[trialId];
        return trial.active && block.timestamp < trial.endTime;
    }

    function getTrialTimeRemaining(bytes32 trialId) external view returns (uint256) {
        Trial memory trial = trials[trialId];
        if (!trial.active || block.timestamp >= trial.endTime) {
            return 0;
        }
        return trial.endTime - block.timestamp;
    }

    function getUserTrials(address user, address creator) external view returns (bytes32[] memory) {
        // This would return all trials for a user with a specific creator
        // Simplified implementation
        bytes32[] memory userTrials = new bytes32[](0);
        return userTrials;
    }

    function getTrial(bytes32 trialId) external view returns (Trial memory) {
        return trials[trialId];
    }

    function getTrialConfig(address creator) external view returns (TrialConfig memory) {
        return trialConfigs[creator];
    }

    function getRemainingTrials(address user, address creator) external view returns (uint256) {
        TrialConfig memory config = trialConfigs[creator];
        uint256 used = userTrialCount[user][creator];
        return config.maxTrialsPerUser > used ? config.maxTrialsPerUser - used : 0;
    }
}
