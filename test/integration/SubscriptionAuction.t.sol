// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/auctions/SubscriptionAuction.sol";

contract SubscriptionAuctionIntegrationTest is Test {
    SubscriptionAuction auction;
    address creator = address(0x1);
    address bidder1 = address(0x2);
    address bidder2 = address(0x3);

    function setUp() public {
        auction = new SubscriptionAuction();
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    function testFullAuctionFlow() public {
        // Create auction
        vm.prank(creator);
        bytes32 auctionId = auction.createAuction(1 ether, 1 days, 30 days);

        // Place bids
        vm.prank(bidder1);
        auction.placeBid{value: 1.5 ether}(auctionId);

        vm.prank(bidder2);
        auction.placeBid{value: 2 ether}(auctionId);

        // Check highest bidder
        (, , uint256 currentBid, address highestBidder, , , , ) = auction.auctions(auctionId);
        assertEq(highestBidder, bidder2);
        assertEq(currentBid, 2 ether);

        // Settle auction
        vm.warp(block.timestamp + 1 days + 1);
        
        uint256 creatorBalanceBefore = creator.balance;
        auction.settleAuction(auctionId);
        
        assertEq(creator.balance, creatorBalanceBefore + 2 ether);
    }

    function testBidRefund() public {
        vm.prank(creator);
        bytes32 auctionId = auction.createAuction(1 ether, 1 days, 30 days);

        vm.prank(bidder1);
        auction.placeBid{value: 1.5 ether}(auctionId);

        uint256 bidder1BalanceBefore = bidder1.balance;
        
        vm.prank(bidder2);
        auction.placeBid{value: 2 ether}(auctionId);

        // bidder1 should be refunded
        assertEq(bidder1.balance, bidder1BalanceBefore);
    }
}
