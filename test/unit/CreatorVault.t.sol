// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract CreatorVaultTest is Test {
    CreatorVault public vault;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public processor = address(0x2);

    uint256 public constant DEPOSIT_AMOUNT = 10 ether;

    function setUp() public {
        vault = new CreatorVault(owner);
        token = new MockERC20("Test Token", "TEST", 18);

        vault.setPaymentProcessor(processor);

        // Fund the processor with tokens
        token.mint(processor, 1000 ether);
    }

    function _depositAsProcessor(address _creator, uint256 amount) internal {
        vm.startPrank(processor);
        token.transfer(address(vault), amount);
        vault.deposit(_creator, address(token), amount, 1);
        vm.stopPrank();
    }
}
