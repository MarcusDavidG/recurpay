// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionLending {
    struct LendingOffer {
        address lender;
        uint256 subscriptionId;
        uint256 lendingFee;
        uint256 duration;
        address borrower;
        uint256 startTime;
        bool active;
        bool completed;
    }

    mapping(bytes32 => LendingOffer) public lendingOffers;
    mapping(address => bytes32[]) public lenderOffers;
    mapping(address => bytes32[]) public borrowerOffers;

    event LendingOfferCreated(bytes32 indexed offerId, address lender, uint256 subscriptionId);
    event SubscriptionBorrowed(bytes32 indexed offerId, address borrower);
    event LendingCompleted(bytes32 indexed offerId);

    function createLendingOffer(
        uint256 subscriptionId,
        uint256 lendingFee,
        uint256 duration
    ) external returns (bytes32 offerId) {
        offerId = keccak256(abi.encodePacked(msg.sender, subscriptionId, block.timestamp));
        
        lendingOffers[offerId] = LendingOffer({
            lender: msg.sender,
            subscriptionId: subscriptionId,
            lendingFee: lendingFee,
            duration: duration,
            borrower: address(0),
            startTime: 0,
            active: true,
            completed: false
        });

        lenderOffers[msg.sender].push(offerId);
        emit LendingOfferCreated(offerId, msg.sender, subscriptionId);
    }

    function borrowSubscription(bytes32 offerId) external payable {
        LendingOffer storage offer = lendingOffers[offerId];
        require(offer.active, "Offer not active");
        require(offer.borrower == address(0), "Already borrowed");
        require(msg.value >= offer.lendingFee, "Insufficient fee");

        offer.borrower = msg.sender;
        offer.startTime = block.timestamp;
        borrowerOffers[msg.sender].push(offerId);

        // Transfer fee to lender
        (bool success, ) = payable(offer.lender).call{value: msg.value}("");
        require(success, "Fee transfer failed");

        emit SubscriptionBorrowed(offerId, msg.sender);
    }

    function completeLending(bytes32 offerId) external {
        LendingOffer storage offer = lendingOffers[offerId];
        require(offer.borrower != address(0), "Not borrowed");
        require(
            block.timestamp >= offer.startTime + offer.duration ||
            msg.sender == offer.borrower ||
            msg.sender == offer.lender,
            "Cannot complete yet"
        );

        offer.active = false;
        offer.completed = true;

        emit LendingCompleted(offerId);
    }

    function getLendingOffer(bytes32 offerId) external view returns (LendingOffer memory) {
        return lendingOffers[offerId];
    }

    function getLenderOffers(address lender) external view returns (bytes32[] memory) {
        return lenderOffers[lender];
    }

    function getBorrowerOffers(address borrower) external view returns (bytes32[] memory) {
        return borrowerOffers[borrower];
    }

    function isLendingActive(bytes32 offerId) external view returns (bool) {
        LendingOffer memory offer = lendingOffers[offerId];
        return offer.active && 
               offer.borrower != address(0) && 
               block.timestamp < offer.startTime + offer.duration;
    }
}
