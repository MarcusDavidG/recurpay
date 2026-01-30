// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/StringUtils.sol";

contract StringUtilsTest is Test {
    using StringUtils for string;

    function testCompare() public {
        assertTrue(StringUtils.compare("hello", "hello"));
        assertFalse(StringUtils.compare("hello", "world"));
        assertTrue(StringUtils.compare("", ""));
    }

    function testLength() public {
        assertEq(StringUtils.length("hello"), 5);
        assertEq(StringUtils.length(""), 0);
        assertEq(StringUtils.length("a"), 1);
    }

    function testConcat() public {
        string memory result = StringUtils.concat("hello", "world");
        assertTrue(StringUtils.compare(result, "helloworld"));
        
        result = StringUtils.concat("", "test");
        assertTrue(StringUtils.compare(result, "test"));
    }

    function testSubstring() public {
        string memory result = StringUtils.substring("hello", 1, 4);
        assertTrue(StringUtils.compare(result, "ell"));
        
        result = StringUtils.substring("test", 0, 2);
        assertTrue(StringUtils.compare(result, "te"));
    }

    function testContains() public {
        assertTrue(StringUtils.contains("hello world", "world"));
        assertTrue(StringUtils.contains("hello world", "hello"));
        assertFalse(StringUtils.contains("hello world", "xyz"));
        assertTrue(StringUtils.contains("test", "test"));
    }

    function testToUpper() public {
        string memory result = StringUtils.toUpper("hello");
        assertTrue(StringUtils.compare(result, "HELLO"));
        
        result = StringUtils.toUpper("Hello World");
        assertTrue(StringUtils.compare(result, "HELLO WORLD"));
    }
}
