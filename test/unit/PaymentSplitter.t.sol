// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/payments/PaymentSplitter.sol";

contract PaymentSplitterTest is Test {
    PaymentSplitter splitter;
    address creator = address(0x1);
    address recipient1 = address(0x2);
    address recipient2 = address(0x3);

    function setUp() public {
        splitter = new PaymentSplitter();
    }

    function testAddSplit() public {
        vm.prank(creator);
        splitter.addSplit(recipient1, 3000); // 30%
        
        (address recipient, uint256 percentage) = splitter.creatorSplits(creator, 0);
        assertEq(recipient, recipient1);
        assertEq(percentage, 3000);
        assertEq(splitter.totalPercentages(creator), 3000);
    }

    function testSplitPayment() public {
        vm.prank(creator);
        splitter.addSplit(recipient1, 3000); // 30%
        vm.prank(creator);
        splitter.addSplit(recipient2, 2000); // 20%

        uint256 amount = 1 ether;
        vm.deal(address(splitter), amount);
        
        uint256 remaining = splitter.splitPayment(creator, amount);
        assertEq(remaining, 0.5 ether); // 50% remaining
        assertEq(recipient1.balance, 0.3 ether);
        assertEq(recipient2.balance, 0.2 ether);
    }

    function testFailExceedsMaxPercentage() public {
        vm.prank(creator);
        splitter.addSplit(recipient1, 6000);
        vm.prank(creator);
        vm.expectRevert("Exceeds 100%");
        splitter.addSplit(recipient2, 5000);
    }
}
