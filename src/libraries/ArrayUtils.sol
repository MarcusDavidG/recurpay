// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ArrayUtils {
    function contains(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) return true;
        }
        return false;
    }

    function indexOf(uint256[] memory array, uint256 value) internal pure returns (int256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) return int256(i);
        }
        return -1;
    }

    function remove(uint256[] memory array, uint256 index) internal pure returns (uint256[] memory) {
        require(index < array.length, "Index out of bounds");
        
        uint256[] memory result = new uint256[](array.length - 1);
        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }
        for (uint256 i = index + 1; i < array.length; i++) {
            result[i - 1] = array[i];
        }
        return result;
    }

    function sum(uint256[] memory array) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < array.length; i++) {
            total += array[i];
        }
        return total;
    }

    function average(uint256[] memory array) internal pure returns (uint256) {
        require(array.length > 0, "Empty array");
        return sum(array) / array.length;
    }

    function sort(uint256[] memory array) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            result[i] = array[i];
        }
        
        // Bubble sort
        for (uint256 i = 0; i < result.length; i++) {
            for (uint256 j = i + 1; j < result.length; j++) {
                if (result[i] > result[j]) {
                    uint256 temp = result[i];
                    result[i] = result[j];
                    result[j] = temp;
                }
            }
        }
        return result;
    }
}
