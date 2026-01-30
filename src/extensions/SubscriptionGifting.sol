// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionGifting {
    struct Gift {
        address giver;
        address recipient;
        address creator;
        uint256 subscriptionId;
        uint256 duration;
        uint256 amount;
        uint256 giftedAt;
        bool claimed;
        string message;
    }

    mapping(bytes32 => Gift) public gifts;
    mapping(address => bytes32[]) public giftsByRecipient;
    mapping(address => bytes32[]) public giftsByGiver;
    
    uint256 public giftCounter;

    event GiftCreated(bytes32 indexed giftId, address indexed giver, address indexed recipient);
    event GiftClaimed(bytes32 indexed giftId, address indexed recipient);
    event GiftRefunded(bytes32 indexed giftId, address indexed giver);

    function createGift(
        address recipient,
        address creator,
        uint256 subscriptionId,
        uint256 duration,
        string memory message
    ) external payable returns (bytes32 giftId) {
        require(recipient != address(0), "Invalid recipient");
        require(msg.value > 0, "No payment provided");

        giftId = keccak256(abi.encodePacked(
            msg.sender,
            recipient,
            creator,
            subscriptionId,
            block.timestamp,
            giftCounter++
        ));

        gifts[giftId] = Gift({
            giver: msg.sender,
            recipient: recipient,
            creator: creator,
            subscriptionId: subscriptionId,
            duration: duration,
            amount: msg.value,
            giftedAt: block.timestamp,
            claimed: false,
            message: message
        });

        giftsByRecipient[recipient].push(giftId);
        giftsByGiver[msg.sender].push(giftId);

        emit GiftCreated(giftId, msg.sender, recipient);
    }

    function claimGift(bytes32 giftId) external {
        Gift storage gift = gifts[giftId];
        require(gift.recipient == msg.sender, "Not the recipient");
        require(!gift.claimed, "Already claimed");
        require(block.timestamp <= gift.giftedAt + 30 days, "Gift expired");

        gift.claimed = true;

        // Transfer funds to creator (simplified)
        (bool success, ) = payable(gift.creator).call{value: gift.amount}("");
        require(success, "Transfer failed");

        emit GiftClaimed(giftId, msg.sender);
    }

    function refundGift(bytes32 giftId) external {
        Gift storage gift = gifts[giftId];
        require(gift.giver == msg.sender, "Not the giver");
        require(!gift.claimed, "Already claimed");
        require(block.timestamp > gift.giftedAt + 30 days, "Gift not expired");

        gift.claimed = true; // Prevent double refund

        (bool success, ) = payable(msg.sender).call{value: gift.amount}("");
        require(success, "Refund failed");

        emit GiftRefunded(giftId, msg.sender);
    }

    function getGiftsByRecipient(address recipient) external view returns (bytes32[] memory) {
        return giftsByRecipient[recipient];
    }

    function getGiftsByGiver(address giver) external view returns (bytes32[] memory) {
        return giftsByGiver[giver];
    }

    function getGift(bytes32 giftId) external view returns (Gift memory) {
        return gifts[giftId];
    }

    function isGiftExpired(bytes32 giftId) external view returns (bool) {
        Gift memory gift = gifts[giftId];
        return block.timestamp > gift.giftedAt + 30 days;
    }

    function getUnclaimedGifts(address recipient) external view returns (bytes32[] memory unclaimed) {
        bytes32[] memory allGifts = giftsByRecipient[recipient];
        uint256 unclaimedCount = 0;

        // Count unclaimed gifts
        for (uint256 i = 0; i < allGifts.length; i++) {
            if (!gifts[allGifts[i]].claimed && !isGiftExpired(allGifts[i])) {
                unclaimedCount++;
            }
        }

        // Create array of unclaimed gifts
        unclaimed = new bytes32[](unclaimedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allGifts.length; i++) {
            if (!gifts[allGifts[i]].claimed && !isGiftExpired(allGifts[i])) {
                unclaimed[index] = allGifts[i];
                index++;
            }
        }
    }
}
