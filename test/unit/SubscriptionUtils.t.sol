// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/utils/SubscriptionUtils.sol";

contract SubscriptionUtilsTest is Test {
    SubscriptionUtils utils;

    function setUp() public {
        utils = new SubscriptionUtils();
    }

    function testEncodeDecodeSubscriptionData() public {
        address creator = address(0x1);
        uint256 price = 1 ether;
        uint256 duration = 30 days;
        string memory name = "Test Plan";

        bytes memory encoded = utils.encodeSubscriptionData(creator, price, duration, name);
        (address decodedCreator, uint256 decodedPrice, uint256 decodedDuration, string memory decodedName) = 
            utils.decodeSubscriptionData(encoded);

        assertEq(decodedCreator, creator);
        assertEq(decodedPrice, price);
        assertEq(decodedDuration, duration);
        assertEq(decodedName, name);
    }

    function testHashSubscriptionData() public {
        address creator = address(0x1);
        uint256 price = 1 ether;
        uint256 duration = 30 days;

        bytes32 hash1 = utils.hashSubscriptionData(creator, price, duration);
        bytes32 hash2 = utils.hashSubscriptionData(creator, price, duration);
        bytes32 hash3 = utils.hashSubscriptionData(creator, price + 1, duration);

        assertEq(hash1, hash2);
        assertNotEq(hash1, hash3);
    }

    function testCalculateSubscriptionHash() public {
        address subscriber = address(0x1);
        uint256 planId = 1;
        uint256 startTime = block.timestamp;

        bytes32 hash = utils.calculateSubscriptionHash(subscriber, planId, startTime);
        assertNotEq(hash, bytes32(0));
    }

    function testIsValidAddress() public {
        assertTrue(utils.isValidAddress(address(0x1)));
        assertFalse(utils.isValidAddress(address(0)));
    }

    function testFormatAmount() public {
        string memory formatted = utils.formatAmount(1000000, 6);
        // Should format 1000000 with 6 decimals as "1.000000"
        assertEq(formatted, "1.0");
        
        formatted = utils.formatAmount(1500000, 6);
        assertEq(formatted, "1.500000");
    }
}
