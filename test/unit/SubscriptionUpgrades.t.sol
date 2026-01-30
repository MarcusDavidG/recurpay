// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/upgrades/SubscriptionUpgrades.sol";

contract SubscriptionUpgradesTest is Test {
    SubscriptionUpgrades upgrades;
    address implementation1 = address(0x1);
    address implementation2 = address(0x2);
    address contract1 = address(0x3);

    function setUp() public {
        upgrades = new SubscriptionUpgrades();
    }

    function testRegisterImplementation() public {
        upgrades.registerImplementation(2, implementation2);
        assertEq(upgrades.getImplementation(2), implementation2);
    }

    function testUpgradeContract() public {
        upgrades.registerImplementation(2, implementation2);
        upgrades.upgradeContract(contract1, 2);
        
        assertEq(upgrades.contractVersions(contract1), 2);
    }

    function testFailUnregisteredVersion() public {
        vm.expectRevert("Version not registered");
        upgrades.upgradeContract(contract1, 999);
    }

    function testFailUnauthorizedUpgrade() public {
        vm.prank(address(0x999));
        vm.expectRevert("Not authorized");
        upgrades.registerImplementation(2, implementation2);
    }
}
