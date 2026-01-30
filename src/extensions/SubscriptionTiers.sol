// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ISubscriptionFactory.sol";
import "../libraries/RecurPayErrors.sol";
import "../libraries/RecurPayEvents.sol";

contract SubscriptionTiers {
    struct Tier {
        uint256 price;
        uint256 duration;
        string name;
        string[] benefits;
        bool active;
        uint256 maxSubscribers;
        uint256 currentSubscribers;
    }

    mapping(address => mapping(uint256 => Tier)) public tiers;
    mapping(address => uint256) public tierCount;

    event TierCreated(address indexed creator, uint256 indexed tierId, string name, uint256 price);
    event TierUpdated(address indexed creator, uint256 indexed tierId);
    event TierDeactivated(address indexed creator, uint256 indexed tierId);

    function createTier(
        string memory name,
        uint256 price,
        uint256 duration,
        string[] memory benefits,
        uint256 maxSubscribers
    ) external returns (uint256 tierId) {
        tierId = tierCount[msg.sender]++;
        
        tiers[msg.sender][tierId] = Tier({
            price: price,
            duration: duration,
            name: name,
            benefits: benefits,
            active: true,
            maxSubscribers: maxSubscribers,
            currentSubscribers: 0
        });

        emit TierCreated(msg.sender, tierId, name, price);
    }

    function updateTierPrice(uint256 tierId, uint256 newPrice) external {
        require(tiers[msg.sender][tierId].active, "Tier not active");
        tiers[msg.sender][tierId].price = newPrice;
        emit TierUpdated(msg.sender, tierId);
    }

    function deactivateTier(uint256 tierId) external {
        tiers[msg.sender][tierId].active = false;
        emit TierDeactivated(msg.sender, tierId);
    }

    function getTier(address creator, uint256 tierId) external view returns (Tier memory) {
        return tiers[creator][tierId];
    }
}
