// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract WebhookManager {
    struct Webhook {
        string url;
        string[] events;
        bool active;
        uint256 createdAt;
        uint256 failureCount;
        uint256 lastSuccess;
    }

    struct WebhookEvent {
        string eventType;
        bytes data;
        uint256 timestamp;
        bool delivered;
        uint256 attempts;
    }

    mapping(address => Webhook[]) public creatorWebhooks;
    mapping(bytes32 => WebhookEvent) public webhookEvents;
    mapping(address => bytes32[]) public creatorEvents;

    event WebhookRegistered(address indexed creator, string url, string[] events);
    event WebhookTriggered(bytes32 indexed eventId, address indexed creator, string eventType);

    function registerWebhook(string memory url, string[] memory events) external {
        creatorWebhooks[msg.sender].push(Webhook({
            url: url,
            events: events,
            active: true,
            createdAt: block.timestamp,
            failureCount: 0,
            lastSuccess: 0
        }));

        emit WebhookRegistered(msg.sender, url, events);
    }

    function triggerWebhook(
        address creator,
        string memory eventType,
        bytes memory data
    ) external returns (bytes32 eventId) {
        eventId = keccak256(abi.encodePacked(creator, eventType, data, block.timestamp));
        
        webhookEvents[eventId] = WebhookEvent({
            eventType: eventType,
            data: data,
            timestamp: block.timestamp,
            delivered: false,
            attempts: 0
        });

        creatorEvents[creator].push(eventId);
        emit WebhookTriggered(eventId, creator, eventType);
    }
}
