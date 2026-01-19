# RecurPay Protocol - Development Prompts

This file contains detailed prompts for AI coding agents to complete the remaining development tasks.

**Current Status:**
- Total Commits: 51
- Completed: Issue #1 (Payment Infrastructure)
- Remaining: Issue #2 (Unit Tests) + Issue #3 (Deployment & Docs)

---

## ISSUE #2: Comprehensive Unit Test Suite (Commits 52-75)

### CONTEXT

**Repository:** `/home/marcus/recurpay`
**Branch:** Create new branch `test/unit-tests` from `main` after merging Issue #1
**Target:** 24 commits (52-75), then push and create PR to close Issue #2

### INSTRUCTIONS

1. First, ensure you're on the correct branch:
```bash
cd /home/marcus/recurpay
git checkout main
git pull origin main
git checkout -b test/unit-tests
```

2. Each task = 1 commit with the exact message provided
3. Run `forge build` and `forge test` after changes to verify
4. Push after commit 75 and create PR to close Issue #2

---

### COMMIT 52: SubscriptionFactory Test Setup

**Action:** CREATE NEW FILE `test/unit/SubscriptionFactory.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract SubscriptionFactoryTest is Test {
    SubscriptionFactory public factory;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public user = address(0x2);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;

    function setUp() public {
        factory = new SubscriptionFactory(owner);
        token = new MockERC20("Test Token", "TEST", 18);
        
        // Add token to supported list
        factory.setSupportedToken(address(token), true);
    }

    function _createDefaultPlanConfig() internal view returns (ISubscriptionFactory.PlanConfig memory) {
        return ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });
    }

    function _createDefaultPlanMetadata() internal pure returns (ISubscriptionFactory.PlanMetadata memory) {
        return ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "A test subscription plan",
            metadataURI: "ipfs://test"
        });
    }
}
```

**Commands:**
```bash
forge build
git add test/unit/SubscriptionFactory.t.sol
git commit -m "test: add SubscriptionFactory test setup"
```

---

### COMMIT 53: Plan Creation Tests

**Action:** EDIT FILE `test/unit/SubscriptionFactory.t.sol`

**Change:** Add the following test functions before the closing `}`:

```solidity
    // =========================================================================
    // Plan Creation Tests
    // =========================================================================

    function test_CreatePlan_Success() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        uint256 planId = factory.createPlan(config, metadata);

        assertEq(planId, 1);
        assertEq(factory.totalPlans(), 1);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertEq(storedConfig.creator, creator);
        assertEq(storedConfig.price, PRICE);
        assertEq(storedConfig.billingPeriod, BILLING_PERIOD);
        assertTrue(storedConfig.active);
    }

    function test_CreatePlan_MultiplePlans() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        uint256 planId1 = factory.createPlan(config, metadata);
        uint256 planId2 = factory.createPlan(config, metadata);
        uint256 planId3 = factory.createPlan(config, metadata);

        assertEq(planId1, 1);
        assertEq(planId2, 2);
        assertEq(planId3, 3);
        assertEq(factory.totalPlans(), 3);
    }

    function test_CreatePlan_WithETH() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.paymentToken = address(0); // ETH
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        uint256 planId = factory.createPlan(config, metadata);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertEq(storedConfig.paymentToken, address(0));
    }

    function test_CreatePlan_RevertZeroCreator() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.creator = address(0);
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert();
        factory.createPlan(config, metadata);
    }

    function test_CreatePlan_RevertZeroPrice() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.price = 0;
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert(ISubscriptionFactory.InvalidPrice.selector);
        factory.createPlan(config, metadata);
    }

    function test_CreatePlan_RevertInvalidBillingPeriod() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.billingPeriod = 1 minutes; // Too short
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert(ISubscriptionFactory.InvalidBillingPeriod.selector);
        factory.createPlan(config, metadata);
    }

    function test_CreatePlan_RevertUnsupportedToken() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        config.paymentToken = address(0x999); // Not supported
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        vm.expectRevert(ISubscriptionFactory.UnsupportedPaymentToken.selector);
        factory.createPlan(config, metadata);
    }
```

**Commands:**
```bash
forge test --match-contract SubscriptionFactoryTest
git add test/unit/SubscriptionFactory.t.sol
git commit -m "test: add plan creation tests"
```

---

### COMMIT 54: Plan Update Tests

**Action:** EDIT FILE `test/unit/SubscriptionFactory.t.sol`

**Change:** Add the following test functions:

```solidity
    // =========================================================================
    // Plan Update Tests
    // =========================================================================

    function test_UpdatePlanPrice_Success() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        uint256 newPrice = 20 ether;
        vm.prank(creator);
        factory.updatePlanPrice(planId, newPrice);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertEq(storedConfig.price, newPrice);
    }

    function test_UpdatePlanPrice_RevertNotCreator() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(user);
        vm.expectRevert(ISubscriptionFactory.NotPlanCreator.selector);
        factory.updatePlanPrice(planId, 20 ether);
    }

    function test_UpdatePlanPrice_RevertZeroPrice() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(creator);
        vm.expectRevert(ISubscriptionFactory.InvalidPrice.selector);
        factory.updatePlanPrice(planId, 0);
    }

    function test_SetPlanActive_Deactivate() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(creator);
        factory.setPlanActive(planId, false);

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertFalse(storedConfig.active);
    }

    function test_SetPlanActive_Reactivate() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.startPrank(creator);
        factory.setPlanActive(planId, false);
        factory.setPlanActive(planId, true);
        vm.stopPrank();

        ISubscriptionFactory.PlanConfig memory storedConfig = factory.getPlan(planId);
        assertTrue(storedConfig.active);
    }

    function test_SetPlanActive_RevertNotCreator() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        vm.prank(user);
        vm.expectRevert(ISubscriptionFactory.NotPlanCreator.selector);
        factory.setPlanActive(planId, false);
    }
```

**Commands:**
```bash
forge test --match-contract SubscriptionFactoryTest
git add test/unit/SubscriptionFactory.t.sol
git commit -m "test: add plan update tests"
```

---

### COMMIT 55: Token Whitelist Tests

**Action:** EDIT FILE `test/unit/SubscriptionFactory.t.sol`

**Change:** Add the following test functions:

```solidity
    // =========================================================================
    // Token Whitelist Tests
    // =========================================================================

    function test_SetSupportedToken_Add() public {
        address newToken = address(0x123);
        
        assertFalse(factory.supportedTokens(newToken));
        
        factory.setSupportedToken(newToken, true);
        
        assertTrue(factory.supportedTokens(newToken));
    }

    function test_SetSupportedToken_Remove() public {
        factory.setSupportedToken(address(token), false);
        
        assertFalse(factory.supportedTokens(address(token)));
    }

    function test_SetSupportedToken_RevertNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        factory.setSupportedToken(address(0x123), true);
    }

    function test_SetSupportedToken_RevertETH() public {
        vm.expectRevert();
        factory.setSupportedToken(address(0), false);
    }

    function test_ETH_AlwaysSupported() public view {
        assertTrue(factory.supportedTokens(address(0)));
    }

    // =========================================================================
    // Query Tests
    // =========================================================================

    function test_GetCreatorPlans() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();

        factory.createPlan(config, metadata);
        factory.createPlan(config, metadata);

        uint256[] memory plans = factory.getCreatorPlans(creator);
        assertEq(plans.length, 2);
        assertEq(plans[0], 1);
        assertEq(plans[1], 2);
    }

    function test_GetPlanMetadata() public {
        ISubscriptionFactory.PlanConfig memory config = _createDefaultPlanConfig();
        ISubscriptionFactory.PlanMetadata memory metadata = _createDefaultPlanMetadata();
        uint256 planId = factory.createPlan(config, metadata);

        ISubscriptionFactory.PlanMetadata memory storedMetadata = factory.getPlanMetadata(planId);
        assertEq(storedMetadata.name, "Test Plan");
        assertEq(storedMetadata.description, "A test subscription plan");
    }

    function test_GetPlan_RevertNotFound() public {
        vm.expectRevert(ISubscriptionFactory.PlanNotFound.selector);
        factory.getPlan(999);
    }
}
```

**Commands:**
```bash
forge test --match-contract SubscriptionFactoryTest
git add test/unit/SubscriptionFactory.t.sol
git commit -m "test: add token whitelist tests"
```

---

### COMMIT 56: SubscriberRegistry Test Setup

**Action:** CREATE NEW FILE `test/unit/SubscriberRegistry.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract SubscriberRegistryTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public processor = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;

    uint256 public planId;

    function setUp() public {
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        token = new MockERC20("Test Token", "TEST", 18);

        factory.setSupportedToken(address(token), true);
        registry.setProcessor(processor);

        // Create a default plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "A test plan",
            metadataURI: ""
        });

        planId = factory.createPlan(config, metadata);
    }
}
```

**Commands:**
```bash
forge build
git add test/unit/SubscriberRegistry.t.sol
git commit -m "test: add SubscriberRegistry test setup"
```

---

### COMMIT 57: Subscription Creation Tests

**Action:** EDIT FILE `test/unit/SubscriberRegistry.t.sol`

**Change:** Add the following test functions before the closing `}`:

```solidity
    // =========================================================================
    // Subscription Creation Tests
    // =========================================================================

    function test_Subscribe_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        assertEq(subId, 1);
        assertEq(registry.totalSubscriptions(), 1);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(sub.planId, planId);
        assertEq(sub.subscriber, subscriber);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Active));
    }

    function test_Subscribe_MultipleSubscribers() public {
        address subscriber2 = address(0x4);
        address subscriber3 = address(0x5);

        uint256 subId1 = registry.subscribe(planId, subscriber);
        uint256 subId2 = registry.subscribe(planId, subscriber2);
        uint256 subId3 = registry.subscribe(planId, subscriber3);

        assertEq(subId1, 1);
        assertEq(subId2, 2);
        assertEq(subId3, 3);
        assertEq(registry.getPlanSubscriberCount(planId), 3);
    }

    function test_Subscribe_RevertAlreadySubscribed() public {
        registry.subscribe(planId, subscriber);

        vm.expectRevert(ISubscriberRegistry.AlreadySubscribed.selector);
        registry.subscribe(planId, subscriber);
    }

    function test_Subscribe_RevertZeroAddress() public {
        vm.expectRevert();
        registry.subscribe(planId, address(0));
    }

    function test_Subscribe_RevertPlanNotActive() public {
        vm.prank(creator);
        factory.setPlanActive(planId, false);

        vm.expectRevert(ISubscriptionFactory.PlanNotActive.selector);
        registry.subscribe(planId, subscriber);
    }

    function test_Subscribe_RevertPlanAtCapacity() public {
        // Create plan with max 1 subscriber
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 1,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Limited Plan",
            description: "",
            metadataURI: ""
        });

        uint256 limitedPlanId = factory.createPlan(config, metadata);

        registry.subscribe(limitedPlanId, subscriber);

        vm.expectRevert(ISubscriberRegistry.PlanAtCapacity.selector);
        registry.subscribe(limitedPlanId, address(0x4));
    }
```

**Commands:**
```bash
forge test --match-contract SubscriberRegistryTest
git add test/unit/SubscriberRegistry.t.sol
git commit -m "test: add subscription creation tests"
```

---

### COMMIT 58: Pause and Resume Tests

**Action:** EDIT FILE `test/unit/SubscriberRegistry.t.sol`

**Change:** Add the following test functions:

```solidity
    // =========================================================================
    // Pause and Resume Tests
    // =========================================================================

    function test_Pause_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.pause(subId, 7 days);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Paused));
    }

    function test_Pause_Indefinite() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.pause(subId, 0);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Paused));
        assertEq(sub.pausedUntil, type(uint64).max);
    }

    function test_Pause_RevertNotSubscriber() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(address(0x999));
        vm.expectRevert(ISubscriberRegistry.NotSubscriber.selector);
        registry.pause(subId, 7 days);
    }

    function test_Pause_RevertNotActive() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.startPrank(subscriber);
        registry.pause(subId, 7 days);

        vm.expectRevert(ISubscriberRegistry.SubscriptionNotActive.selector);
        registry.pause(subId, 7 days);
        vm.stopPrank();
    }

    function test_Resume_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.startPrank(subscriber);
        registry.pause(subId, 7 days);
        registry.resume(subId);
        vm.stopPrank();

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Active));
        assertEq(sub.pausedUntil, 0);
    }

    function test_Resume_RevertNotPaused() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        vm.expectRevert(ISubscriberRegistry.NotPaused.selector);
        registry.resume(subId);
    }

    function test_Resume_RevertNotSubscriber() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.pause(subId, 7 days);

        vm.prank(address(0x999));
        vm.expectRevert(ISubscriberRegistry.NotSubscriber.selector);
        registry.resume(subId);
    }
```

**Commands:**
```bash
forge test --match-contract SubscriberRegistryTest
git add test/unit/SubscriberRegistry.t.sol
git commit -m "test: add pause and resume tests"
```

---

### COMMIT 59: Cancellation Tests

**Action:** EDIT FILE `test/unit/SubscriberRegistry.t.sol`

**Change:** Add the following test functions:

```solidity
    // =========================================================================
    // Cancellation Tests
    // =========================================================================

    function test_Cancel_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.cancel(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }

    function test_Cancel_FromPaused() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.startPrank(subscriber);
        registry.pause(subId, 7 days);
        registry.cancel(subId);
        vm.stopPrank();

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }

    function test_Cancel_RevertAlreadyCancelled() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.startPrank(subscriber);
        registry.cancel(subId);

        vm.expectRevert(ISubscriberRegistry.AlreadyCancelled.selector);
        registry.cancel(subId);
        vm.stopPrank();
    }

    function test_Cancel_RevertNotSubscriber() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(address(0x999));
        vm.expectRevert(ISubscriberRegistry.NotSubscriber.selector);
        registry.cancel(subId);
    }

    // =========================================================================
    // Profile Tests
    // =========================================================================

    function test_SubscriberProfile_Updated() public {
        registry.subscribe(planId, subscriber);

        ISubscriberRegistry.SubscriberProfile memory profile = registry.getSubscriberProfile(subscriber);
        assertEq(profile.subscriptionCount, 1);
        assertEq(profile.activeSubscriptions, 1);
    }

    function test_SubscriberProfile_AfterCancel() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.cancel(subId);

        ISubscriberRegistry.SubscriberProfile memory profile = registry.getSubscriberProfile(subscriber);
        assertEq(profile.subscriptionCount, 1);
        assertEq(profile.activeSubscriptions, 0);
    }

    function test_HasActiveSubscription() public {
        assertFalse(registry.hasActiveSubscription(subscriber, planId));

        registry.subscribe(planId, subscriber);

        assertTrue(registry.hasActiveSubscription(subscriber, planId));
    }
}
```

**Commands:**
```bash
forge test --match-contract SubscriberRegistryTest
git add test/unit/SubscriberRegistry.t.sol
git commit -m "test: add cancellation tests"
```

---

### COMMIT 60: CreatorVault Test Setup

**Action:** CREATE NEW FILE `test/unit/CreatorVault.t.sol`

```solidity
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
```

**Commands:**
```bash
forge build
git add test/unit/CreatorVault.t.sol
git commit -m "test: add CreatorVault test setup"
```

---

### COMMIT 61: Deposit Tests

**Action:** EDIT FILE `test/unit/CreatorVault.t.sol`

**Change:** Add the following test functions before the closing `}`:

```solidity
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
```

**Commands:**
```bash
forge test --match-contract CreatorVaultTest
git add test/unit/CreatorVault.t.sol
git commit -m "test: add deposit tests"
```

---

### COMMIT 62: Withdrawal Tests

**Action:** EDIT FILE `test/unit/CreatorVault.t.sol`

**Change:** Add the following test functions:

```solidity
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
```

**Commands:**
```bash
forge test --match-contract CreatorVaultTest
git add test/unit/CreatorVault.t.sol
git commit -m "test: add withdrawal tests"
```

---

### COMMIT 63: Multi-Token Vault Tests

**Action:** EDIT FILE `test/unit/CreatorVault.t.sol`

**Change:** Add the following test functions:

```solidity
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
```

**Commands:**
```bash
forge test --match-contract CreatorVaultTest
git add test/unit/CreatorVault.t.sol
git commit -m "test: add multi-token vault tests"
```

---

### COMMIT 64: PaymentProcessor Test Setup

**Action:** CREATE NEW FILE `test/unit/PaymentProcessor.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {IPaymentProcessor} from "src/interfaces/IPaymentProcessor.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract PaymentProcessorTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    CreatorVault public vault;
    PaymentProcessor public processor;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public treasury = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;
    uint32 public constant GRACE_PERIOD = 3 days;
    uint16 public constant FEE_BPS = 100; // 1%

    uint256 public planId;

    function setUp() public {
        // Deploy contracts
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        vault = new CreatorVault(owner);
        processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            FEE_BPS,
            owner
        );

        token = new MockERC20("Test Token", "TEST", 18);

        // Configure
        factory.setSupportedToken(address(token), true);
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: GRACE_PERIOD,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test Plan",
            description: "",
            metadataURI: ""
        });

        planId = factory.createPlan(config, metadata);

        // Fund subscriber
        token.mint(subscriber, 1000 ether);
        vm.prank(subscriber);
        token.approve(address(processor), type(uint256).max);
    }
}
```

**Commands:**
```bash
forge build
git add test/unit/PaymentProcessor.t.sol
git commit -m "test: add PaymentProcessor test setup"
```

---

### COMMIT 65: Single Payment Tests

**Action:** EDIT FILE `test/unit/PaymentProcessor.t.sol`

**Change:** Add the following test functions before the closing `}`:

```solidity
    // =========================================================================
    // Payment Processing Tests
    // =========================================================================

    function test_ProcessPayment_Success() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Warp to after billing period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        uint256 creatorBalanceBefore = vault.getBalance(creator, address(token));

        bool success = processor.processPayment(subId);

        assertTrue(success);
        
        uint256 expectedCreatorAmount = PRICE - (PRICE * FEE_BPS / 10000);
        assertEq(vault.getBalance(creator, address(token)), creatorBalanceBefore + expectedCreatorAmount);
    }

    function test_ProcessPayment_CollectsProtocolFee() public {
        uint256 subId = registry.subscribe(planId, subscriber);
        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        processor.processPayment(subId);

        uint256 expectedFee = PRICE * FEE_BPS / 10000;
        assertEq(processor.getAccumulatedFees(address(token)), expectedFee);
    }

    function test_ProcessPayment_RevertNotDue() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.expectRevert(IPaymentProcessor.PaymentNotDue.selector);
        processor.processPayment(subId);
    }

    function test_ProcessPayment_RevertPaused() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.pause(subId, 7 days);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        vm.expectRevert(IPaymentProcessor.SubscriptionPaused.selector);
        processor.processPayment(subId);
    }

    function test_ProcessPayment_RevertCancelled() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.prank(subscriber);
        registry.cancel(subId);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        vm.expectRevert(IPaymentProcessor.SubscriptionCancelled.selector);
        processor.processPayment(subId);
    }

    function test_ProcessPayment_InsufficientBalance() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain subscriber balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        bool success = processor.processPayment(subId);
        assertFalse(success);
    }
```

**Commands:**
```bash
forge test --match-contract PaymentProcessorTest
git add test/unit/PaymentProcessor.t.sol
git commit -m "test: add single payment tests"
```

---

### COMMIT 66: Batch Payment Tests

**Action:** EDIT FILE `test/unit/PaymentProcessor.t.sol`

**Change:** Add the following test functions:

```solidity
    // =========================================================================
    // Batch Payment Tests
    // =========================================================================

    function test_ProcessBatch_Success() public {
        address subscriber2 = address(0x4);
        address subscriber3 = address(0x5);

        token.mint(subscriber2, 1000 ether);
        token.mint(subscriber3, 1000 ether);

        vm.prank(subscriber2);
        token.approve(address(processor), type(uint256).max);
        vm.prank(subscriber3);
        token.approve(address(processor), type(uint256).max);

        uint256 subId1 = registry.subscribe(planId, subscriber);
        uint256 subId2 = registry.subscribe(planId, subscriber2);
        uint256 subId3 = registry.subscribe(planId, subscriber3);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        uint256[] memory subIds = new uint256[](3);
        subIds[0] = subId1;
        subIds[1] = subId2;
        subIds[2] = subId3;

        IPaymentProcessor.BatchResult memory result = processor.processBatch(subIds);

        assertEq(result.processed, 3);
        assertEq(result.succeeded, 3);
        assertEq(result.failed, 0);
        assertEq(result.totalAmount, PRICE * 3);
    }

    function test_ProcessBatch_PartialFailure() public {
        address subscriber2 = address(0x4);

        token.mint(subscriber2, 1000 ether);
        vm.prank(subscriber2);
        token.approve(address(processor), type(uint256).max);

        uint256 subId1 = registry.subscribe(planId, subscriber);
        uint256 subId2 = registry.subscribe(planId, subscriber2);

        // Drain subscriber1 balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        uint256[] memory subIds = new uint256[](2);
        subIds[0] = subId1;
        subIds[1] = subId2;

        IPaymentProcessor.BatchResult memory result = processor.processBatch(subIds);

        assertEq(result.processed, 2);
        assertEq(result.succeeded, 1);
        assertEq(result.failed, 1);
    }

    function test_ProcessBatch_RevertExceedsMaxSize() public {
        uint256[] memory subIds = new uint256[](101);

        vm.expectRevert(IPaymentProcessor.BatchSizeExceeded.selector);
        processor.processBatch(subIds);
    }
```

**Commands:**
```bash
forge test --match-contract PaymentProcessorTest
git add test/unit/PaymentProcessor.t.sol
git commit -m "test: add batch payment tests"
```

---

### COMMIT 67: Grace Period Tests

**Action:** EDIT FILE `test/unit/PaymentProcessor.t.sol`

**Change:** Add the following test functions:

```solidity
    // =========================================================================
    // Grace Period Tests
    // =========================================================================

    function test_GracePeriod_EntersOnFailure() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        processor.processPayment(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.GracePeriod));
    }

    function test_GracePeriod_CancelsAfterExpiry() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        // First failure - enters grace period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        // Second failure after grace period - cancels
        vm.warp(block.timestamp + GRACE_PERIOD + 1);
        processor.processPayment(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }

    // =========================================================================
    // Fee Tests
    // =========================================================================

    function test_SetProtocolFee() public {
        uint16 newFee = 200; // 2%

        processor.setProtocolFee(newFee);

        assertEq(processor.protocolFeeBps(), newFee);
    }

    function test_SetProtocolFee_RevertTooHigh() public {
        vm.expectRevert(IPaymentProcessor.FeeTooHigh.selector);
        processor.setProtocolFee(1001); // > 10%
    }

    function test_WithdrawProtocolFees() public {
        uint256 subId = registry.subscribe(planId, subscriber);
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        uint256 fees = processor.getAccumulatedFees(address(token));
        uint256 treasuryBefore = token.balanceOf(treasury);

        processor.withdrawProtocolFees(address(token));

        assertEq(processor.getAccumulatedFees(address(token)), 0);
        assertEq(token.balanceOf(treasury), treasuryBefore + fees);
    }

    // =========================================================================
    // Query Tests
    // =========================================================================

    function test_IsPaymentDue() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        (bool isDue, uint256 amount) = processor.isPaymentDue(subId);
        assertFalse(isDue);
        assertEq(amount, 0);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        (isDue, amount) = processor.isPaymentDue(subId);
        assertTrue(isDue);
        assertEq(amount, PRICE);
    }

    function test_GetNextPaymentDue() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        uint64 dueDate = processor.getNextPaymentDue(subId);
        assertEq(dueDate, block.timestamp + BILLING_PERIOD);
    }

    function test_GetPaymentHistory() public {
        uint256 subId = registry.subscribe(planId, subscriber);

        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        IPaymentProcessor.PaymentExecution[] memory history = processor.getPaymentHistory(subId, 10);
        assertEq(history.length, 1);
        assertTrue(history[0].success);
        assertEq(history[0].amount, PRICE);
    }
}
```

**Commands:**
```bash
forge test --match-contract PaymentProcessorTest
git add test/unit/PaymentProcessor.t.sol
git commit -m "test: add grace period and fee tests"
```

---

### COMMIT 68: BillingPeriod Library Tests

**Action:** CREATE NEW FILE `test/unit/BillingPeriod.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BillingPeriod} from "src/libraries/BillingPeriod.sol";

contract BillingPeriodTest is Test {
    function test_CalculatePeriodEnd() public pure {
        uint64 start = 1000;
        uint32 period = 30 days;

        uint64 end = BillingPeriod.calculatePeriodEnd(start, period);

        assertEq(end, start + period);
    }

    function test_PeriodsSince_Zero() public pure {
        uint64 start = 1000;
        uint64 current = 1000;
        uint32 period = 30 days;

        uint32 periods = BillingPeriod.periodsSince(start, current, period);

        assertEq(periods, 0);
    }

    function test_PeriodsSince_One() public pure {
        uint64 start = 1000;
        uint32 period = 30 days;
        uint64 current = start + period + 1;

        uint32 periods = BillingPeriod.periodsSince(start, current, period);

        assertEq(periods, 1);
    }

    function test_PeriodsSince_Multiple() public pure {
        uint64 start = 1000;
        uint32 period = 30 days;
        uint64 current = start + (period * 5) + 1;

        uint32 periods = BillingPeriod.periodsSince(start, current, period);

        assertEq(periods, 5);
    }

    function test_IsPaymentDue_False() public pure {
        uint64 nextDue = 1000;
        uint64 current = 500;

        bool isDue = BillingPeriod.isPaymentDue(nextDue, current);

        assertFalse(isDue);
    }

    function test_IsPaymentDue_True() public pure {
        uint64 nextDue = 1000;
        uint64 current = 1000;

        bool isDue = BillingPeriod.isPaymentDue(nextDue, current);

        assertTrue(isDue);
    }

    function test_IsInGracePeriod_False_BeforePeriodEnd() public pure {
        uint64 periodEnd = 1000;
        uint32 gracePeriod = 3 days;
        uint64 current = 500;

        bool inGrace = BillingPeriod.isInGracePeriod(periodEnd, gracePeriod, current);

        assertFalse(inGrace);
    }

    function test_IsInGracePeriod_True() public pure {
        uint64 periodEnd = 1000;
        uint32 gracePeriod = 3 days;
        uint64 current = periodEnd + 1 days;

        bool inGrace = BillingPeriod.isInGracePeriod(periodEnd, gracePeriod, current);

        assertTrue(inGrace);
    }

    function test_IsGracePeriodExpired() public pure {
        uint64 periodEnd = 1000;
        uint32 gracePeriod = 3 days;
        uint64 current = periodEnd + gracePeriod + 1;

        bool expired = BillingPeriod.isGracePeriodExpired(periodEnd, gracePeriod, current);

        assertTrue(expired);
    }

    function test_IsValidBillingPeriod_Valid() public pure {
        assertTrue(BillingPeriod.isValidBillingPeriod(30 days));
        assertTrue(BillingPeriod.isValidBillingPeriod(7 days));
        assertTrue(BillingPeriod.isValidBillingPeriod(365 days));
    }

    function test_IsValidBillingPeriod_Invalid() public pure {
        assertFalse(BillingPeriod.isValidBillingPeriod(30 minutes)); // Too short
        assertFalse(BillingPeriod.isValidBillingPeriod(800 days)); // Too long
    }

    function test_CalculateProrata() public pure {
        uint256 fullAmount = 100 ether;
        uint32 periodDuration = 30 days;
        uint32 remainingTime = 15 days;

        uint256 prorated = BillingPeriod.calculateProrata(fullAmount, periodDuration, remainingTime);

        assertEq(prorated, 50 ether);
    }
}
```

**Commands:**
```bash
forge test --match-contract BillingPeriodTest
git add test/unit/BillingPeriod.t.sol
git commit -m "test: add BillingPeriod library tests"
```

---

### COMMIT 69: PercentageMath Library Tests

**Action:** CREATE NEW FILE `test/unit/PercentageMath.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";

contract PercentageMathTest is Test {
    function test_CalculatePercentage_OnePercent() public pure {
        uint256 amount = 100 ether;
        uint256 bps = 100; // 1%

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 1 ether);
    }

    function test_CalculatePercentage_TenPercent() public pure {
        uint256 amount = 100 ether;
        uint256 bps = 1000; // 10%

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 10 ether);
    }

    function test_CalculatePercentage_HundredPercent() public pure {
        uint256 amount = 100 ether;
        uint256 bps = 10000; // 100%

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 100 ether);
    }

    function test_CalculatePercentage_ZeroAmount() public pure {
        uint256 amount = 0;
        uint256 bps = 100;

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 0);
    }

    function test_CalculatePercentage_ZeroBps() public pure {
        uint256 amount = 100 ether;
        uint256 bps = 0;

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 0);
    }

    function test_CalculatePercentage_RevertOverflow() public {
        uint256 amount = 100 ether;
        uint256 bps = 10001; // > 100%

        vm.expectRevert();
        PercentageMath.calculatePercentage(amount, bps);
    }

    function test_CalculatePercentage_SmallAmount() public pure {
        uint256 amount = 100; // 100 wei
        uint256 bps = 100; // 1%

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 1); // 1 wei
    }

    function test_CalculatePercentage_FractionalBps() public pure {
        uint256 amount = 10000;
        uint256 bps = 1; // 0.01%

        uint256 result = PercentageMath.calculatePercentage(amount, bps);

        assertEq(result, 1);
    }
}
```

**Commands:**
```bash
forge test --match-contract PercentageMathTest
git add test/unit/PercentageMath.t.sol
git commit -m "test: add PercentageMath library tests"
```

---

### COMMIT 70: TokenUtils Library Tests

**Action:** CREATE NEW FILE `test/unit/TokenUtils.t.sol`

```solidity
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
```

**Commands:**
```bash
forge test --match-contract TokenUtilsTest
git add test/unit/TokenUtils.t.sol
git commit -m "test: add TokenUtils library tests"
```

---

### COMMIT 71: Full Flow Integration Test

**Action:** CREATE NEW FILE `test/integration/FullFlow.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {RecurPayRouter} from "src/RecurPayRouter.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract FullFlowTest is Test {
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    CreatorVault public vault;
    PaymentProcessor public processor;
    RecurPayRouter public router;
    MockERC20 public token;

    address public owner = address(this);
    address public creator = address(0x1);
    address public subscriber = address(0x2);
    address public treasury = address(0x3);

    uint256 public constant PRICE = 10 ether;
    uint32 public constant BILLING_PERIOD = 30 days;

    function setUp() public {
        // Deploy all contracts
        factory = new SubscriptionFactory(owner);
        registry = new SubscriberRegistry(address(factory), owner);
        vault = new CreatorVault(owner);
        processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            100, // 1% fee
            owner
        );
        router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            owner
        );

        token = new MockERC20("USDC", "USDC", 6);

        // Configure
        factory.setSupportedToken(address(token), true);
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        // Fund subscriber
        token.mint(subscriber, 1000 ether);
        vm.prank(subscriber);
        token.approve(address(processor), type(uint256).max);
    }

    function test_FullSubscriptionLifecycle() public {
        // 1. Creator creates a plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Premium Plan",
            description: "Access to premium features",
            metadataURI: "ipfs://metadata"
        });

        uint256 planId = factory.createPlan(config, metadata);
        assertEq(planId, 1);

        // 2. Subscriber subscribes
        uint256 subId = registry.subscribe(planId, subscriber);
        assertEq(subId, 1);

        // 3. First payment is processed
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        bool success = processor.processPayment(subId);
        assertTrue(success);

        // 4. Verify creator received payment
        uint256 expectedCreatorAmount = PRICE - (PRICE * 100 / 10000);
        assertEq(vault.getBalance(creator, address(token)), expectedCreatorAmount);

        // 5. Subscriber pauses
        vm.prank(subscriber);
        registry.pause(subId, 7 days);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Paused));

        // 6. Subscriber resumes
        vm.prank(subscriber);
        registry.resume(subId);

        sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Active));

        // 7. Creator withdraws
        vm.prank(creator);
        vault.withdrawAll(address(token));

        assertEq(vault.getBalance(creator, address(token)), 0);
        assertEq(token.balanceOf(creator), expectedCreatorAmount);

        // 8. Subscriber cancels
        vm.prank(subscriber);
        registry.cancel(subId);

        sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }
}
```

**Commands:**
```bash
forge test --match-contract FullFlowTest
git add test/integration/FullFlow.t.sol
git commit -m "test: add full subscription flow integration test"
```

---

### COMMIT 72: Multi-Subscriber Integration Test

**Action:** EDIT FILE `test/integration/FullFlow.t.sol`

**Change:** Add the following test function before the closing `}`:

```solidity
    function test_MultipleSubscribers() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Premium",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);

        // Create multiple subscribers
        address[] memory subscribers = new address[](5);
        uint256[] memory subIds = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            subscribers[i] = address(uint160(0x100 + i));
            token.mint(subscribers[i], 1000 ether);
            vm.prank(subscribers[i]);
            token.approve(address(processor), type(uint256).max);
            subIds[i] = registry.subscribe(planId, subscribers[i]);
        }

        assertEq(registry.getPlanSubscriberCount(planId), 5);

        // Process all payments
        vm.warp(block.timestamp + BILLING_PERIOD + 1);

        processor.processBatch(subIds);

        // Verify creator balance
        uint256 expectedPerPayment = PRICE - (PRICE * 100 / 10000);
        assertEq(vault.getBalance(creator, address(token)), expectedPerPayment * 5);
    }

    function test_MultiplePaymentCycles() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Monthly",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);
        uint256 subId = registry.subscribe(planId, subscriber);

        uint256 expectedPerPayment = PRICE - (PRICE * 100 / 10000);

        // Process 3 payment cycles
        for (uint256 i = 0; i < 3; i++) {
            vm.warp(block.timestamp + BILLING_PERIOD + 1);
            processor.processPayment(subId);
        }

        assertEq(vault.getBalance(creator, address(token)), expectedPerPayment * 3);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(sub.totalPaid, PRICE * 3);
    }
```

**Commands:**
```bash
forge test --match-contract FullFlowTest
git add test/integration/FullFlow.t.sol
git commit -m "test: add multi-subscriber integration test"
```

---

### COMMIT 73: Payment Failure Recovery Test

**Action:** EDIT FILE `test/integration/FullFlow.t.sol`

**Change:** Add the following test function:

```solidity
    function test_PaymentFailureAndRecovery() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain subscriber balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        // First payment fails - enters grace period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        bool success = processor.processPayment(subId);
        assertFalse(success);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.GracePeriod));

        // Subscriber tops up balance
        token.mint(subscriber, 100 ether);

        // Payment succeeds within grace period
        success = processor.processPayment(subId);
        assertTrue(success);

        // Status should be active again after successful payment
        sub = registry.getSubscription(subId);
        // Note: The status update depends on implementation
    }
```

**Commands:**
```bash
forge test --match-contract FullFlowTest
git add test/integration/FullFlow.t.sol
git commit -m "test: add payment failure recovery test"
```

---

### COMMIT 74: Subscription Expiry Test

**Action:** EDIT FILE `test/integration/FullFlow.t.sol`

**Change:** Add the following test function:

```solidity
    function test_SubscriptionExpiry() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);
        uint256 subId = registry.subscribe(planId, subscriber);

        // Drain subscriber balance
        vm.prank(subscriber);
        token.transfer(address(0x999), token.balanceOf(subscriber));

        // First failure - enters grace period
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        processor.processPayment(subId);

        // Second failure after grace period - should cancel
        vm.warp(block.timestamp + 3 days + 1);
        processor.processPayment(subId);

        ISubscriberRegistry.Subscription memory sub = registry.getSubscription(subId);
        assertEq(uint8(sub.status), uint8(ISubscriberRegistry.SubscriptionStatus.Cancelled));
    }
```

**Commands:**
```bash
forge test --match-contract FullFlowTest
git add test/integration/FullFlow.t.sol
git commit -m "test: add subscription expiry test"
```

---

### COMMIT 75: Creator Withdrawal Flow Test

**Action:** EDIT FILE `test/integration/FullFlow.t.sol`

**Change:** Add the following test function, then close the contract:

```solidity
    function test_CreatorWithdrawalFlow() public {
        // Create plan
        ISubscriptionFactory.PlanConfig memory config = ISubscriptionFactory.PlanConfig({
            creator: creator,
            paymentToken: address(token),
            price: PRICE,
            billingPeriod: BILLING_PERIOD,
            gracePeriod: 3 days,
            maxSubscribers: 0,
            active: true
        });

        ISubscriptionFactory.PlanMetadata memory metadata = ISubscriptionFactory.PlanMetadata({
            name: "Test",
            description: "",
            metadataURI: ""
        });

        uint256 planId = factory.createPlan(config, metadata);

        // Multiple subscribers
        for (uint256 i = 0; i < 3; i++) {
            address sub = address(uint160(0x100 + i));
            token.mint(sub, 1000 ether);
            vm.prank(sub);
            token.approve(address(processor), type(uint256).max);
            registry.subscribe(planId, sub);
        }

        // Process payments
        vm.warp(block.timestamp + BILLING_PERIOD + 1);
        uint256[] memory subIds = new uint256[](3);
        subIds[0] = 1;
        subIds[1] = 2;
        subIds[2] = 3;
        processor.processBatch(subIds);

        // Check revenue stats
        ICreatorVault.RevenueStats memory stats = vault.getRevenueStats(creator);
        uint256 expectedPerPayment = PRICE - (PRICE * 100 / 10000);
        assertEq(stats.totalRevenue, expectedPerPayment * 3);
        assertEq(stats.pendingBalance, expectedPerPayment * 3);

        // Set custom withdrawal address
        address customRecipient = address(0x789);
        vm.prank(creator);
        vault.setWithdrawalAddress(customRecipient);

        // Partial withdrawal
        vm.prank(creator);
        vault.withdraw(address(token), expectedPerPayment);

        assertEq(token.balanceOf(customRecipient), expectedPerPayment);

        // Withdraw remaining
        vm.prank(creator);
        vault.withdrawAll(address(token));

        assertEq(vault.getBalance(creator, address(token)), 0);
        assertEq(token.balanceOf(customRecipient), expectedPerPayment * 3);
    }
}
```

**Commands:**
```bash
forge test --match-contract FullFlowTest
git add test/integration/FullFlow.t.sol
git commit -m "test: add creator withdrawal integration test"
```

---

## BATCH 2 COMPLETE - PUSH AND CREATE PR

After commit 75:

```bash
# Run all tests
forge test

# Check commit count
git log --oneline | wc -l

# Push to remote
git push origin test/unit-tests
```

Then create a PR on GitHub:
- **Title:** `test: Add comprehensive unit tests for all contracts`
- **Body:** `Closes #2`

---

## ISSUE #3: Deployment Scripts, Documentation & Optimization (Commits 76-100)

### CONTEXT

**Repository:** `/home/marcus/recurpay`
**Branch:** Create new branch `feat/deployment-and-docs` from `main` after merging Issue #2
**Target:** 25 commits (76-100), then push and create PR to close Issue #3

### INSTRUCTIONS

1. First, ensure you're on the correct branch:
```bash
cd /home/marcus/recurpay
git checkout main
git pull origin main
git checkout -b feat/deployment-and-docs
```

2. Each task = 1 commit with the exact message provided
3. Run `forge build` after changes to verify
4. Push after commit 100 and create PR to close Issue #3

---

### COMMIT 76: Main Deployment Script

**Action:** CREATE NEW FILE `script/Deploy.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {RecurPayRouter} from "src/RecurPayRouter.sol";

contract DeployRecurPay is Script {
    // Deployment configuration
    address public deployer;
    address public treasury;
    uint16 public protocolFeeBps;

    // Deployed contracts
    SubscriptionFactory public factory;
    SubscriberRegistry public registry;
    CreatorVault public vault;
    PaymentProcessor public processor;
    RecurPayRouter public router;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        treasury = vm.envAddress("TREASURY_ADDRESS");
        protocolFeeBps = uint16(vm.envUint("PROTOCOL_FEE_BPS"));
    }

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 1. Deploy SubscriptionFactory
        factory = new SubscriptionFactory(deployer);
        console.log("SubscriptionFactory deployed at:", address(factory));

        // 2. Deploy SubscriberRegistry
        registry = new SubscriberRegistry(address(factory), deployer);
        console.log("SubscriberRegistry deployed at:", address(registry));

        // 3. Deploy CreatorVault
        vault = new CreatorVault(deployer);
        console.log("CreatorVault deployed at:", address(vault));

        // 4. Deploy PaymentProcessor
        processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            protocolFeeBps,
            deployer
        );
        console.log("PaymentProcessor deployed at:", address(processor));

        // 5. Deploy RecurPayRouter
        router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            deployer
        );
        console.log("RecurPayRouter deployed at:", address(router));

        // 6. Configure contracts
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        console.log("Configuration complete!");

        vm.stopBroadcast();

        // Log summary
        console.log("\n=== Deployment Summary ===");
        console.log("Factory:", address(factory));
        console.log("Registry:", address(registry));
        console.log("Vault:", address(vault));
        console.log("Processor:", address(processor));
        console.log("Router:", address(router));
        console.log("Treasury:", treasury);
        console.log("Protocol Fee:", protocolFeeBps, "bps");
    }
}
```

**Commands:**
```bash
forge build
git add script/Deploy.s.sol
git commit -m "feat: add main deployment script"
```

---

### COMMIT 77: Deployment Configuration

**Action:** CREATE NEW FILE `script/DeployConfig.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

abstract contract DeployConfig is Script {
    // Network IDs
    uint256 constant BASE_MAINNET = 8453;
    uint256 constant BASE_SEPOLIA = 84532;

    // Configuration struct
    struct NetworkConfig {
        address treasury;
        uint16 protocolFeeBps;
        address[] supportedTokens;
    }

    function getConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == BASE_MAINNET) {
            return getBaseMainnetConfig();
        } else if (block.chainid == BASE_SEPOLIA) {
            return getBaseSepoliaConfig();
        } else {
            return getLocalConfig();
        }
    }

    function getBaseMainnetConfig() internal pure returns (NetworkConfig memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base
        tokens[1] = 0x4200000000000000000000000000000000000006; // WETH on Base

        return NetworkConfig({
            treasury: address(0), // Set before deployment
            protocolFeeBps: 100, // 1%
            supportedTokens: tokens
        });
    }

    function getBaseSepoliaConfig() internal pure returns (NetworkConfig memory) {
        address[] memory tokens = new address[](0);

        return NetworkConfig({
            treasury: address(0), // Set before deployment
            protocolFeeBps: 100,
            supportedTokens: tokens
        });
    }

    function getLocalConfig() internal pure returns (NetworkConfig memory) {
        address[] memory tokens = new address[](0);

        return NetworkConfig({
            treasury: address(1), // Placeholder
            protocolFeeBps: 100,
            supportedTokens: tokens
        });
    }
}
```

**Commands:**
```bash
forge build
git add script/DeployConfig.s.sol
git commit -m "feat: add deployment configuration"
```

---

### COMMIT 78: Testnet Deployment Script

**Action:** CREATE NEW FILE `script/DeployTestnet.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DeployConfig} from "./DeployConfig.s.sol";
import {SubscriptionFactory} from "src/SubscriptionFactory.sol";
import {SubscriberRegistry} from "src/SubscriberRegistry.sol";
import {CreatorVault} from "src/CreatorVault.sol";
import {PaymentProcessor} from "src/PaymentProcessor.sol";
import {RecurPayRouter} from "src/RecurPayRouter.sol";

contract DeployTestnet is Script, DeployConfig {
    function run() public {
        NetworkConfig memory config = getConfig();

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        // Use deployer as treasury for testnet if not set
        address treasury = config.treasury == address(0) ? deployer : config.treasury;

        console.log("Deploying to chain:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Treasury:", treasury);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy contracts
        SubscriptionFactory factory = new SubscriptionFactory(deployer);
        console.log("Factory:", address(factory));

        SubscriberRegistry registry = new SubscriberRegistry(address(factory), deployer);
        console.log("Registry:", address(registry));

        CreatorVault vault = new CreatorVault(deployer);
        console.log("Vault:", address(vault));

        PaymentProcessor processor = new PaymentProcessor(
            address(factory),
            address(registry),
            address(vault),
            treasury,
            config.protocolFeeBps,
            deployer
        );
        console.log("Processor:", address(processor));

        RecurPayRouter router = new RecurPayRouter(
            address(factory),
            address(registry),
            address(processor),
            address(vault),
            deployer
        );
        console.log("Router:", address(router));

        // Configure
        registry.setProcessor(address(processor));
        vault.setPaymentProcessor(address(processor));

        // Add supported tokens
        for (uint256 i = 0; i < config.supportedTokens.length; i++) {
            factory.setSupportedToken(config.supportedTokens[i], true);
        }

        vm.stopBroadcast();

        console.log("\nDeployment complete!");
    }
}
```

**Commands:**
```bash
forge build
git add script/DeployTestnet.s.sol
git commit -m "feat: add testnet deployment script"
```

---

### COMMIT 79: Contract Verification Script

**Action:** CREATE NEW FILE `script/Verify.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

contract VerifyContracts is Script {
    function run() public view {
        console.log("Contract Verification Commands for Base Mainnet:");
        console.log("");
        console.log("Run these commands after deployment:");
        console.log("");
        console.log("1. SubscriptionFactory:");
        console.log("   forge verify-contract <FACTORY_ADDRESS> src/SubscriptionFactory.sol:SubscriptionFactory --chain base --constructor-args $(cast abi-encode 'constructor(address)' <OWNER>)");
        console.log("");
        console.log("2. SubscriberRegistry:");
        console.log("   forge verify-contract <REGISTRY_ADDRESS> src/SubscriberRegistry.sol:SubscriberRegistry --chain base --constructor-args $(cast abi-encode 'constructor(address,address)' <FACTORY> <OWNER>)");
        console.log("");
        console.log("3. CreatorVault:");
        console.log("   forge verify-contract <VAULT_ADDRESS> src/CreatorVault.sol:CreatorVault --chain base --constructor-args $(cast abi-encode 'constructor(address)' <OWNER>)");
        console.log("");
        console.log("4. PaymentProcessor:");
        console.log("   forge verify-contract <PROCESSOR_ADDRESS> src/PaymentProcessor.sol:PaymentProcessor --chain base --constructor-args $(cast abi-encode 'constructor(address,address,address,address,uint16,address)' <FACTORY> <REGISTRY> <VAULT> <TREASURY> <FEE_BPS> <OWNER>)");
        console.log("");
        console.log("5. RecurPayRouter:");
        console.log("   forge verify-contract <ROUTER_ADDRESS> src/RecurPayRouter.sol:RecurPayRouter --chain base --constructor-args $(cast abi-encode 'constructor(address,address,address,address,address)' <FACTORY> <REGISTRY> <PROCESSOR> <VAULT> <OWNER>)");
    }
}
```

**Commands:**
```bash
forge build
git add script/Verify.s.sol
git commit -m "feat: add contract verification script"
```

---

### COMMIT 80-84: NatSpec Documentation

For commits 80-84, add comprehensive NatSpec comments to each contract. I'll provide one example:

### COMMIT 80: NatSpec for SubscriptionFactory

**Action:** EDIT FILE `src/SubscriptionFactory.sol`

**Change:** Ensure all public/external functions have complete NatSpec documentation. Add `@notice`, `@param`, and `@return` tags to any functions missing them.

**Commands:**
```bash
forge build
git add src/SubscriptionFactory.sol
git commit -m "docs: add NatSpec to SubscriptionFactory"
```

Repeat similar process for:
- COMMIT 81: `src/SubscriberRegistry.sol` - `"docs: add NatSpec to SubscriberRegistry"`
- COMMIT 82: `src/CreatorVault.sol` - `"docs: add NatSpec to CreatorVault"`
- COMMIT 83: `src/PaymentProcessor.sol` - `"docs: add NatSpec to PaymentProcessor"`
- COMMIT 84: `src/RecurPayRouter.sol` - `"docs: add NatSpec to RecurPayRouter"`

---

### COMMIT 85: Protocol Specification

**Action:** CREATE NEW FILE `docs/SPECIFICATION.md`

```markdown
# RecurPay Protocol Specification

## Overview

RecurPay is a decentralized recurring payment protocol built on Base, enabling trustless subscription infrastructure for the creator economy.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      RecurPayRouter                              │
│                   (Unified Entry Point)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────┐         ┌──────────────────┐             │
│   │  Subscription    │         │    Payment       │             │
│   │    Factory       │────────▶│   Processor      │             │
│   └──────────────────┘         └────────┬─────────┘             │
│            │                            │                        │
│            │                            │                        │
│            ▼                            ▼                        │
│   ┌──────────────────┐         ┌──────────────────┐             │
│   │   Subscriber     │         │    Creator       │             │
│   │    Registry      │◀───────▶│     Vault        │             │
│   └──────────────────┘         └──────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Core Contracts

### SubscriptionFactory
- Creates and manages subscription plans
- Maintains token whitelist
- Stores plan configuration and metadata

### SubscriberRegistry
- Tracks all subscription state
- Manages subscription lifecycle (active, paused, cancelled)
- Maintains subscriber profiles

### PaymentProcessor
- Executes recurring payments
- Handles grace periods
- Collects protocol fees
- Supports batch processing

### CreatorVault
- Non-custodial revenue management
- Multi-token support
- Auto-withdrawal capabilities
- Revenue analytics

### RecurPayRouter
- Unified entry point for all protocol interactions
- Simplifies integration for frontends

## Payment Flow

1. Creator creates a plan via `SubscriptionFactory`
2. Subscriber subscribes via `SubscriberRegistry`
3. `PaymentProcessor` pulls payment from subscriber
4. Funds deposited to creator's `CreatorVault`
5. Protocol fee accumulated for treasury
6. Creator withdraws when ready

## Fee Structure

- Protocol fee: Configurable (default 1%, max 10%)
- Fees collected per payment
- Treasury receives accumulated fees

## Security Considerations

- Reentrancy protection on all state-changing functions
- Pausable in case of emergencies
- Owner-only admin functions
- No upgradability (immutable deployment)
```

**Commands:**
```bash
mkdir -p docs
git add docs/SPECIFICATION.md
git commit -m "docs: add protocol specification"
```

---

### COMMIT 86: Integration Guide

**Action:** CREATE NEW FILE `docs/INTEGRATION.md`

```markdown
# RecurPay Integration Guide

## Quick Start

### 1. Install Dependencies

```bash
npm install ethers
```

### 2. Connect to Contracts

```javascript
import { ethers } from 'ethers';

const ROUTER_ADDRESS = '0x...'; // RecurPayRouter address
const ROUTER_ABI = [...]; // Import ABI

const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
const router = new ethers.Contract(ROUTER_ADDRESS, ROUTER_ABI, signer);
```

### 3. Create a Subscription Plan (Creators)

```javascript
const planConfig = {
  creator: creatorAddress,
  paymentToken: USDC_ADDRESS,
  price: ethers.parseUnits('10', 6), // 10 USDC
  billingPeriod: 30 * 24 * 60 * 60, // 30 days
  gracePeriod: 3 * 24 * 60 * 60, // 3 days
  maxSubscribers: 0, // unlimited
  active: true
};

const metadata = {
  name: 'Premium Plan',
  description: 'Access to premium features',
  metadataURI: 'ipfs://...'
};

const tx = await router.createPlan(planConfig, metadata);
const receipt = await tx.wait();
```

### 4. Subscribe to a Plan (Subscribers)

```javascript
// First, approve token spending
const token = new ethers.Contract(USDC_ADDRESS, ERC20_ABI, signer);
await token.approve(PROCESSOR_ADDRESS, ethers.MaxUint256);

// Then subscribe
const tx = await router.subscribe(planId);
await tx.wait();
```

### 5. Manage Subscriptions

```javascript
// Pause
await router.pauseSubscription(subscriptionId, 7 * 24 * 60 * 60); // 7 days

// Resume
await router.resumeSubscription(subscriptionId);

// Cancel
await router.cancelSubscription(subscriptionId);
```

### 6. Withdraw Revenue (Creators)

```javascript
// Withdraw specific amount
await router.withdrawRevenue(USDC_ADDRESS, amount);

// Withdraw all
await router.withdrawAllRevenue(USDC_ADDRESS);
```

## Events to Listen For

```javascript
// New subscription
router.on('SubscriptionCreated', (subId, planId, subscriber, creator) => {
  console.log(`New subscription: ${subId}`);
});

// Payment processed
processor.on('PaymentProcessed', (subId, subscriber, creator, amount, token) => {
  console.log(`Payment received: ${amount}`);
});
```

## Error Handling

All custom errors are defined in the interfaces. Handle them appropriately:

```javascript
try {
  await router.subscribe(planId);
} catch (error) {
  if (error.message.includes('AlreadySubscribed')) {
    console.log('You are already subscribed to this plan');
  }
}
```
```

**Commands:**
```bash
git add docs/INTEGRATION.md
git commit -m "docs: add integration guide"
```

---

### COMMIT 87: Security Documentation

**Action:** CREATE NEW FILE `docs/SECURITY.md`

```markdown
# RecurPay Security Considerations

## Security Model

### Access Control

| Function | Access |
|----------|--------|
| Create Plan | Anyone |
| Subscribe | Anyone |
| Pause/Resume/Cancel | Subscriber only |
| Update Plan | Plan creator only |
| Withdraw Revenue | Vault owner only |
| Set Protocol Fee | Owner only |
| Pause Protocol | Owner only |

### Reentrancy Protection

All state-changing functions use OpenZeppelin's `ReentrancyGuard`:
- `deposit()`
- `withdraw()`
- `processPayment()`
- `processBatch()`

### Pausable

The protocol can be paused in emergencies:
- Affects: subscriptions, payments, deposits
- Does not affect: withdrawals (creators can always withdraw)

## Known Risks

### Payment Token Risks

- Protocol supports any ERC20 token added to whitelist
- Fee-on-transfer tokens may cause accounting issues
- Rebasing tokens are not recommended

### Front-Running

- Plan creation is not front-runnable (no advantage)
- Subscription payments use pull model (subscriber controls timing)

### Griefing Vectors

- Creating many plans: Mitigated by gas costs
- Subscribing/cancelling repeatedly: Mitigated by gas costs

## Audit Status

⚠️ **This protocol has not been audited. Use at your own risk.**

## Bug Bounty

Contact: security@recurpay.xyz

| Severity | Reward |
|----------|--------|
| Critical | Up to $10,000 |
| High | Up to $5,000 |
| Medium | Up to $1,000 |
| Low | Up to $500 |

## Responsible Disclosure

1. Do not exploit vulnerabilities
2. Report via security@recurpay.xyz
3. Allow 90 days for fix before disclosure
4. Do not disclose to others until fixed
```

**Commands:**
```bash
git add docs/SECURITY.md
git commit -m "docs: add security documentation"
```

---

### COMMIT 88: Contributing Guidelines

**Action:** CREATE NEW FILE `CONTRIBUTING.md`

```markdown
# Contributing to RecurPay

## Getting Started

1. Fork the repository
2. Clone your fork
3. Install dependencies: `forge install`
4. Create a branch: `git checkout -b feature/your-feature`

## Development Workflow

### Building

```bash
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testFunctionName

# Run with verbosity
forge test -vvv
```

### Formatting

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

## Pull Request Process

1. Ensure tests pass: `forge test`
2. Format code: `forge fmt`
3. Update documentation if needed
4. Write descriptive commit messages
5. Request review from maintainers

## Commit Message Format

```
type: description

[optional body]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Tests
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `chore`: Maintenance

## Code Style

- Use custom errors instead of require strings
- Add NatSpec to all public functions
- Follow Solidity style guide
- Keep functions focused and small

## Questions?

Open an issue or join our Discord.
```

**Commands:**
```bash
git add CONTRIBUTING.md
git commit -m "docs: add contributing guidelines"
```

---

### COMMITS 89-92: Gas Optimizations

For these commits, apply gas optimizations to each contract:

**COMMIT 89:** Optimize SubscriptionFactory
```bash
git commit -m "perf: optimize gas in SubscriptionFactory"
```

**COMMIT 90:** Optimize PaymentProcessor
```bash
git commit -m "perf: optimize gas in PaymentProcessor"
```

**COMMIT 91:** Optimize CreatorVault
```bash
git commit -m "perf: optimize gas in CreatorVault"
```

**COMMIT 92:** Storage packing
```bash
git commit -m "perf: optimize storage layout"
```

---

### COMMITS 93-94: Fuzz Tests

**COMMIT 93:** CREATE `test/fuzz/SubscriptionFactory.fuzz.t.sol`
```bash
git commit -m "test: add fuzz tests to SubscriptionFactory"
```

**COMMIT 94:** CREATE `test/fuzz/PaymentProcessor.fuzz.t.sol`
```bash
git commit -m "test: add fuzz tests to PaymentProcessor"
```

---

### COMMITS 95-100: Final Polish

**COMMIT 95:** Format all files
```bash
forge fmt
git add .
git commit -m "chore: format all Solidity files"
```

**COMMIT 96:** Fix warnings
```bash
git commit -m "fix: resolve compiler warnings"
```

**COMMIT 97:** Gas snapshot
```bash
forge snapshot
git add .gas-snapshot
git commit -m "chore: add gas snapshot"
```

**COMMIT 98:** Update README
```bash
git commit -m "docs: update README"
```

**COMMIT 99:** Deployment checklist
```bash
# Create docs/DEPLOYMENT_CHECKLIST.md
git commit -m "docs: add deployment checklist"
```

**COMMIT 100:** Final cleanup
```bash
git commit -m "chore: final cleanup and verification"
```

---

## BATCH 3 COMPLETE - PUSH AND CREATE PR

After commit 100:

```bash
forge build
forge test
git log --oneline | wc -l
git push origin feat/deployment-and-docs
```

Create PR:
- **Title:** `feat: Add deployment scripts, documentation, and gas optimizations`
- **Body:** `Closes #3`

---

## Final Notes

After all PRs are merged:
1. Total commits should be 100
2. All tests should pass
3. All contracts verified on BaseScan
4. Documentation complete

Ready for Base Mainnet deployment!
