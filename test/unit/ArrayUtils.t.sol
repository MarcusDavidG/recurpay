// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/ArrayUtils.sol";

contract ArrayUtilsTest is Test {
    function testContains() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        
        assertTrue(ArrayUtils.contains(arr, 2));
        assertFalse(ArrayUtils.contains(arr, 4));
    }

    function testIndexOf() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        
        assertEq(ArrayUtils.indexOf(arr, 20), 1);
        assertEq(ArrayUtils.indexOf(arr, 40), -1);
    }

    function testSum() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        
        assertEq(ArrayUtils.sum(arr), 6);
    }

    function testAverage() public {
        uint256[] memory arr = new uint256[](4);
        arr[0] = 2;
        arr[1] = 4;
        arr[2] = 6;
        arr[3] = 8;
        
        assertEq(ArrayUtils.average(arr), 5);
    }

    function testSort() public {
        uint256[] memory arr = new uint256[](4);
        arr[0] = 3;
        arr[1] = 1;
        arr[2] = 4;
        arr[3] = 2;
        
        uint256[] memory sorted = ArrayUtils.sort(arr);
        assertEq(sorted[0], 1);
        assertEq(sorted[1], 2);
        assertEq(sorted[2], 3);
        assertEq(sorted[3], 4);
    }

    function testRemove() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        
        uint256[] memory result = ArrayUtils.remove(arr, 1);
        assertEq(result.length, 2);
        assertEq(result[0], 1);
        assertEq(result[1], 3);
    }
}
