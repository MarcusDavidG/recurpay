// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/lending/SubscriptionLending.sol";

contract SubscriptionLendingIntegrationTest is Test {
    SubscriptionLending lending;
    address lender = address(0x1);
    address borrower = address(0x2);

    function setUp() public {
        lending = new SubscriptionLending();
        vm.deal(borrower, 10 ether);
    }

    function testLendingFlow() public {
        // Create lending offer
        vm.prank(lender);
        bytes32 offerId = lending.createLendingOffer(1, 0.1 ether, 7 days);

        // Borrow subscription
        vm.prank(borrower);
        lending.borrowSubscription{value: 0.1 ether}(offerId);

        // Check lending state
        (address offerLender, uint256 subscriptionId, uint256 lendingFee, uint256 duration, address offerBorrower, uint256 startTime, bool active, bool completed) = lending.lendingOffers(offerId);
        assertEq(offerLender, lender);
        assertEq(offerBorrower, borrower);
        assertEq(lendingFee, 0.1 ether);
        assertTrue(active);
        assertFalse(completed);

        // Complete lending after duration
        vm.warp(block.timestamp + 7 days + 1);
        lending.completeLending(offerId);

        (, , , , , , active, completed) = lending.lendingOffers(offerId);
        assertFalse(active);
        assertTrue(completed);
    }

    function testEarlyCompletion() public {
        vm.prank(lender);
        bytes32 offerId = lending.createLendingOffer(1, 0.1 ether, 7 days);

        vm.prank(borrower);
        lending.borrowSubscription{value: 0.1 ether}(offerId);

        // Borrower completes early
        vm.prank(borrower);
        lending.completeLending(offerId);

        (, , , , , , bool active, bool completed) = lending.lendingOffers(offerId);
        assertFalse(active);
        assertTrue(completed);
    }
}
