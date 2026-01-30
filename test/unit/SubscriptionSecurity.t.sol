// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/security/SubscriptionSecurity.sol";

contract SubscriptionSecurityTest is Test {
    SubscriptionSecurity security;
    address user = address(0x1);

    function setUp() public {
        security = new SubscriptionSecurity();
    }

    function testBlacklistUser() public {
        security.blacklistUser(user);
        assertTrue(security.blacklisted(user));
        assertFalse(security.isUserSafe(user));
    }

    function testSuspiciousActivity() public {
        for (uint256 i = 0; i < 5; i++) {
            security.reportSuspiciousActivity(user);
        }
        
        assertEq(security.suspiciousActivity(user), 5);
        assertTrue(security.isUserSafe(user)); // Still safe
        
        // Report more to trigger blacklist
        for (uint256 i = 0; i < 6; i++) {
            security.reportSuspiciousActivity(user);
        }
        
        assertTrue(security.blacklisted(user));
        assertFalse(security.isUserSafe(user));
    }

    function testRemoveFromBlacklist() public {
        security.blacklistUser(user);
        assertTrue(security.blacklisted(user));
        
        security.removeFromBlacklist(user);
        assertFalse(security.blacklisted(user));
        assertTrue(security.isUserSafe(user));
    }
}
