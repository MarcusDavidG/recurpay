// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionAuction {
    struct Auction {
        address creator;
        uint256 startingPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        uint256 subscriptionDuration;
        bool active;
        bool settled;
    }

    mapping(bytes32 => Auction) public auctions;
    mapping(bytes32 => mapping(address => uint256)) public bids;
    mapping(address => bytes32[]) public creatorAuctions;

    event AuctionCreated(bytes32 indexed auctionId, address creator, uint256 startingPrice);
    event BidPlaced(bytes32 indexed auctionId, address bidder, uint256 amount);
    event AuctionSettled(bytes32 indexed auctionId, address winner, uint256 finalBid);

    function createAuction(
        uint256 startingPrice,
        uint256 duration,
        uint256 subscriptionDuration
    ) external returns (bytes32 auctionId) {
        auctionId = keccak256(abi.encodePacked(msg.sender, startingPrice, block.timestamp));
        
        auctions[auctionId] = Auction({
            creator: msg.sender,
            startingPrice: startingPrice,
            currentBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + duration,
            subscriptionDuration: subscriptionDuration,
            active: true,
            settled: false
        });

        creatorAuctions[msg.sender].push(auctionId);
        emit AuctionCreated(auctionId, msg.sender, startingPrice);
    }

    function placeBid(bytes32 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.currentBid, "Bid too low");
        require(msg.value >= auction.startingPrice, "Below starting price");

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{value: auction.currentBid}("");
            require(success, "Refund failed");
        }

        auction.currentBid = msg.value;
        auction.highestBidder = msg.sender;
        bids[auctionId][msg.sender] = msg.value;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function settleAuction(bytes32 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(!auction.settled, "Already settled");

        auction.active = false;
        auction.settled = true;

        if (auction.highestBidder != address(0)) {
            // Transfer payment to creator
            (bool success, ) = payable(auction.creator).call{value: auction.currentBid}("");
            require(success, "Payment failed");

            emit AuctionSettled(auctionId, auction.highestBidder, auction.currentBid);
        }
    }

    function getAuction(bytes32 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

    function isAuctionActive(bytes32 auctionId) external view returns (bool) {
        Auction memory auction = auctions[auctionId];
        return auction.active && block.timestamp < auction.endTime;
    }

    function getCreatorAuctions(address creator) external view returns (bytes32[] memory) {
        return creatorAuctions[creator];
    }
}
