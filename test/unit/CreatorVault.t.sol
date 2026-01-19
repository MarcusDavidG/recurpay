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

    // =========================================================================
    // Vault Creation Tests
    // =========================================================================

    function test_CreateVault_Success() public {
        uint256 vaultId = vault.createVault(creator);

        assertEq(vaultId, 1);
        assertTrue(vault.hasVault(creator));
    }

    function test_CreateVault_RevertAlreadyExists() public {
        vault.createVault(creator);

        vm.expectRevert();
        vault.createVault(creator);
    }

    function test_CreateVault_RevertZeroAddress() public {
        vm.expectRevert();
        vault.createVault(address(0));
    }

    // =========================================================================
    // Deposit Tests
    // =========================================================================

    function test_Deposit_Success() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        assertEq(vault.getBalance(creator, address(token)), DEPOSIT_AMOUNT);
        assertTrue(vault.hasVault(creator));
    }

    function test_Deposit_AutoCreatesVault() public {
        assertFalse(vault.hasVault(creator));

        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        assertTrue(vault.hasVault(creator));
    }

    function test_Deposit_MultipleDeposits() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        assertEq(vault.getBalance(creator, address(token)), DEPOSIT_AMOUNT * 2);
    }

    function test_Deposit_RevertNotProcessor() public {
        vm.prank(address(0x999));
        vm.expectRevert();
        vault.deposit(creator, address(token), DEPOSIT_AMOUNT, 1);
    }

    function test_Deposit_RevertZeroAmount() public {
        vm.prank(processor);
        vm.expectRevert(ICreatorVault.ZeroDeposit.selector);
        vault.deposit(creator, address(token), 0, 1);
    }

    function test_Deposit_UpdatesRevenueStats() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        ICreatorVault.RevenueStats memory stats = vault.getRevenueStats(creator);
        assertEq(stats.totalRevenue, DEPOSIT_AMOUNT);
        assertEq(stats.pendingBalance, DEPOSIT_AMOUNT);
        assertEq(stats.totalWithdrawn, 0);
    }

    function test_Deposit_ETH() public {
        vm.deal(processor, 10 ether);

        vm.prank(processor);
        vault.deposit{value: 1 ether}(creator, address(0), 1 ether, 1);

        assertEq(vault.getBalance(creator, address(0)), 1 ether);
    }

    // =========================================================================
    // Withdrawal Tests
    // =========================================================================

    function test_Withdraw_Success() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        uint256 balanceBefore = token.balanceOf(creator);

        vm.prank(creator);
        vault.withdraw(address(token), DEPOSIT_AMOUNT);

        assertEq(vault.getBalance(creator, address(token)), 0);
        assertEq(token.balanceOf(creator), balanceBefore + DEPOSIT_AMOUNT);
    }

    function test_Withdraw_Partial() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        vm.prank(creator);
        vault.withdraw(address(token), DEPOSIT_AMOUNT / 2);

        assertEq(vault.getBalance(creator, address(token)), DEPOSIT_AMOUNT / 2);
    }

    function test_WithdrawAll_Success() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        vm.prank(creator);
        vault.withdrawAll(address(token));

        assertEq(vault.getBalance(creator, address(token)), 0);
    }

    function test_Withdraw_RevertNotVaultOwner() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        vm.prank(address(0x999));
        vm.expectRevert(ICreatorVault.NotVaultOwner.selector);
        vault.withdraw(address(token), DEPOSIT_AMOUNT);
    }

    function test_Withdraw_RevertInsufficientBalance() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        vm.prank(creator);
        vm.expectRevert(ICreatorVault.InsufficientVaultBalance.selector);
        vault.withdraw(address(token), DEPOSIT_AMOUNT * 2);
    }

    function test_Withdraw_UpdatesRevenueStats() public {
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        vm.prank(creator);
        vault.withdraw(address(token), DEPOSIT_AMOUNT);

        ICreatorVault.RevenueStats memory stats = vault.getRevenueStats(creator);
        assertEq(stats.totalRevenue, DEPOSIT_AMOUNT);
        assertEq(stats.pendingBalance, 0);
        assertEq(stats.totalWithdrawn, DEPOSIT_AMOUNT);
    }

    function test_SetWithdrawalAddress_Success() public {
        vault.createVault(creator);
        address newRecipient = address(0x123);

        vm.prank(creator);
        vault.setWithdrawalAddress(newRecipient);

        assertEq(vault.getWithdrawalAddress(creator), newRecipient);
    }

    function test_SetWithdrawalAddress_RevertZero() public {
        vault.createVault(creator);

        vm.prank(creator);
        vm.expectRevert(ICreatorVault.InvalidWithdrawalAddress.selector);
        vault.setWithdrawalAddress(address(0));
    }

    // =========================================================================
    // Multi-Token Tests
    // =========================================================================

    function test_MultiToken_Deposits() public {
        MockERC20 token2 = new MockERC20("Token 2", "TK2", 18);
        token2.mint(processor, 1000 ether);

        // Deposit token 1
        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        // Deposit token 2
        vm.startPrank(processor);
        token2.transfer(address(vault), DEPOSIT_AMOUNT * 2);
        vault.deposit(creator, address(token2), DEPOSIT_AMOUNT * 2, 2);
        vm.stopPrank();

        assertEq(vault.getBalance(creator, address(token)), DEPOSIT_AMOUNT);
        assertEq(vault.getBalance(creator, address(token2)), DEPOSIT_AMOUNT * 2);
    }

    function test_GetAllBalances() public {
        MockERC20 token2 = new MockERC20("Token 2", "TK2", 18);
        token2.mint(processor, 1000 ether);

        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        vm.startPrank(processor);
        token2.transfer(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(creator, address(token2), DEPOSIT_AMOUNT, 2);
        vm.stopPrank();

        ICreatorVault.TokenBalance[] memory balances = vault.getAllBalances(creator);
        assertEq(balances.length, 2);
    }

    // =========================================================================
    // Auto-Withdrawal Tests
    // =========================================================================

    function test_ConfigureAutoWithdrawal() public {
        vault.createVault(creator);

        vm.prank(creator);
        vault.configureAutoWithdrawal(true, 5 ether);

        (bool enabled, uint256 threshold) = vault.getAutoWithdrawalConfig(creator);
        assertTrue(enabled);
        assertEq(threshold, 5 ether);
    }

    function test_AutoWithdrawal_Triggers() public {
        vault.createVault(creator);

        vm.prank(creator);
        vault.configureAutoWithdrawal(true, 5 ether);

        uint256 balanceBefore = token.balanceOf(creator);

        _depositAsProcessor(creator, DEPOSIT_AMOUNT);

        // Balance should be auto-withdrawn
        assertEq(vault.getBalance(creator, address(token)), 0);
        assertEq(token.balanceOf(creator), balanceBefore + DEPOSIT_AMOUNT);
    }
}
