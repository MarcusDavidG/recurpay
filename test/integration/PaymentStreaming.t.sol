// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/payments/PaymentStreaming.sol";

contract PaymentStreamingIntegrationTest is Test {
    PaymentStreaming streaming;
    address sender = address(0x1);
    address recipient = address(0x2);

    function setUp() public {
        streaming = new PaymentStreaming();
        vm.deal(sender, 10 ether);
    }

    function testCreateAndWithdrawStream() public {
        vm.prank(sender);
        bytes32 streamId = streaming.createStream{value: 1 ether}(recipient, 100 days);

        // Fast forward 50 days (half the duration)
        vm.warp(block.timestamp + 50 days);

        uint256 available = streaming.getAvailableAmount(streamId);
        assertApproxEqAbs(available, 0.5 ether, 0.01 ether); // Should be approximately half

        uint256 balanceBefore = recipient.balance;
        vm.prank(recipient);
        streaming.withdrawFromStream(streamId);

        assertGt(recipient.balance, balanceBefore);
    }

    function testFullStreamWithdrawal() public {
        vm.prank(sender);
        bytes32 streamId = streaming.createStream{value: 1 ether}(recipient, 100 days);

        // Fast forward past the full duration
        vm.warp(block.timestamp + 101 days);

        uint256 available = streaming.getAvailableAmount(streamId);
        assertEq(available, 1 ether); // Should be full amount

        vm.prank(recipient);
        streaming.withdrawFromStream(streamId);

        assertEq(recipient.balance, 1 ether);
    }

    function testMultipleWithdrawals() public {
        vm.prank(sender);
        bytes32 streamId = streaming.createStream{value: 1 ether}(recipient, 100 days);

        // First withdrawal at 25 days
        vm.warp(block.timestamp + 25 days);
        vm.prank(recipient);
        streaming.withdrawFromStream(streamId);

        uint256 balanceAfterFirst = recipient.balance;

        // Second withdrawal at 75 days
        vm.warp(block.timestamp + 50 days);
        vm.prank(recipient);
        streaming.withdrawFromStream(streamId);

        assertGt(recipient.balance, balanceAfterFirst);
    }

    function testFailUnauthorizedWithdrawal() public {
        vm.prank(sender);
        bytes32 streamId = streaming.createStream{value: 1 ether}(recipient, 100 days);

        vm.warp(block.timestamp + 50 days);

        vm.expectRevert("Not recipient");
        streaming.withdrawFromStream(streamId);
    }
}
