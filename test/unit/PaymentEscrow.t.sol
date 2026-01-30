// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/payments/PaymentEscrow.sol";

contract PaymentEscrowTest is Test {
    PaymentEscrow escrow;
    address payer = address(0x1);
    address payee = address(0x2);

    function setUp() public {
        escrow = new PaymentEscrow();
        vm.deal(payer, 10 ether);
    }

    function testCreateDeposit() public {
        vm.prank(payer);
        bytes32 depositId = escrow.createDeposit{value: 1 ether}(payee, 1 days);
        
        (address depositPayer, address depositPayee, uint256 amount, uint256 releaseTime, bool released, bool disputed) = escrow.deposits(depositId);
        assertEq(depositPayer, payer);
        assertEq(depositPayee, payee);
        assertEq(amount, 1 ether);
        assertFalse(released);
        assertFalse(disputed);
    }

    function testReleaseDeposit() public {
        vm.prank(payer);
        bytes32 depositId = escrow.createDeposit{value: 1 ether}(payee, 1 days);
        
        vm.warp(block.timestamp + 1 days + 1);
        
        uint256 balanceBefore = payee.balance;
        escrow.releaseDeposit(depositId);
        assertEq(payee.balance, balanceBefore + 1 ether);
    }

    function testFailEarlyRelease() public {
        vm.prank(payer);
        bytes32 depositId = escrow.createDeposit{value: 1 ether}(payee, 1 days);
        
        vm.expectRevert("Not yet releasable");
        escrow.releaseDeposit(depositId);
    }
}
