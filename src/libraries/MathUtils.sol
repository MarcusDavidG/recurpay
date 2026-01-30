// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MathUtils {
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b) / 2;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    function compound(uint256 principal, uint256 rate, uint256 periods) internal pure returns (uint256) {
        uint256 result = principal;
        for (uint256 i = 0; i < periods; i++) {
            result = (result * (10000 + rate)) / 10000;
        }
        return result;
    }

    function percentage(uint256 amount, uint256 percent) internal pure returns (uint256) {
        return (amount * percent) / 10000;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
