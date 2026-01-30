// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/config/SubscriptionConfig.sol";

contract SubscriptionConfigTest is Test {
    SubscriptionConfig config;
    address user = address(0x1);

    function setUp() public {
        config = new SubscriptionConfig();
        config.authorize(user);
    }

    function testSetConfig() public {
        bytes memory value = abi.encode(uint256(100));
        
        vm.prank(user);
        config.setConfig("maxSubscribers", value);

        bytes memory retrieved = config.getConfig("maxSubscribers");
        assertEq(retrieved, value);
    }

    function testGetConfigAsUint() public {
        uint256 testValue = 500;
        bytes memory value = abi.encode(testValue);
        
        vm.prank(user);
        config.setConfig("feeRate", value);

        uint256 retrieved = config.getConfigAsUint("feeRate");
        assertEq(retrieved, testValue);
    }

    function testGetConfigAsString() public {
        string memory testValue = "test_string";
        bytes memory value = abi.encode(testValue);
        
        vm.prank(user);
        config.setConfig("serviceName", value);

        string memory retrieved = config.getConfigAsString("serviceName");
        assertEq(retrieved, testValue);
    }

    function testRemoveConfig() public {
        bytes memory value = abi.encode(uint256(100));
        
        vm.prank(user);
        config.setConfig("testKey", value);

        vm.prank(user);
        config.removeConfig("testKey");

        vm.expectRevert("Config not found");
        config.getConfig("testKey");
    }

    function testGetAllConfigKeys() public {
        vm.prank(user);
        config.setConfig("key1", abi.encode(uint256(1)));
        
        vm.prank(user);
        config.setConfig("key2", abi.encode(uint256(2)));

        string[] memory keys = config.getAllConfigKeys();
        assertEq(keys.length, 2);
    }

    function testFailUnauthorized() public {
        bytes memory value = abi.encode(uint256(100));
        
        vm.expectRevert("Not authorized");
        config.setConfig("testKey", value);
    }
}
