// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenUtils} from "src/libraries/TokenUtils.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {MockFailingERC20} from "test/mocks/MockFailingERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenUtilsTest is Test {
    MockERC20 public token;
    MockFailingERC20 public failingToken;

    address public sender = address(this);
    address public recipient = address(0x1);

    function setUp() public {
        token = new MockERC20("Test", "TEST", 18);
        failingToken = new MockFailingERC20();

        token.mint(sender, 1000 ether);
        failingToken.mint(sender, 1000 ether);
    }

    function test_SafeTransfer_Success() public {
        TokenUtils.safeTransfer(IERC20(address(token)), recipient, 100 ether);

        assertEq(token.balanceOf(recipient), 100 ether);
    }

    function test_SafeTransfer_ZeroAmount() public {
        TokenUtils.safeTransfer(IERC20(address(token)), recipient, 0);

        assertEq(token.balanceOf(recipient), 0);
    }

    function test_SafeTransferFrom_Success() public {
        token.approve(address(this), 100 ether);

        TokenUtils.safeTransferFrom(IERC20(address(token)), sender, recipient, 100 ether);

        assertEq(token.balanceOf(recipient), 100 ether);
    }

    function test_SafeTransferETH_Success() public {
        vm.deal(address(this), 10 ether);

        TokenUtils.safeTransferETH(recipient, 1 ether);

        assertEq(recipient.balance, 1 ether);
    }

    function test_SafeTransferETH_ZeroAmount() public {
        TokenUtils.safeTransferETH(recipient, 0);

        assertEq(recipient.balance, 0);
    }

    function test_SafeTransferETH_RevertOnFailure() public {
        // Contract that rejects ETH
        RejectETH rejecter = new RejectETH();
        vm.deal(address(this), 10 ether);

        vm.expectRevert();
        TokenUtils.safeTransferETH(address(rejecter), 1 ether);
    }
}

contract RejectETH {
    receive() external payable {
        revert("No ETH");
    }
}
