// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/MathUtils.sol";

contract MathUtilsTest is Test {
    using MathUtils for uint256;

    function testAverage() public {
        assertEq(MathUtils.average(10, 20), 15);
        assertEq(MathUtils.average(0, 100), 50);
        assertEq(MathUtils.average(5, 5), 5);
    }

    function testMinMax() public {
        assertEq(MathUtils.min(10, 20), 10);
        assertEq(MathUtils.max(10, 20), 20);
        assertEq(MathUtils.min(5, 5), 5);
        assertEq(MathUtils.max(5, 5), 5);
    }

    function testAbs() public {
        assertEq(MathUtils.abs(10), 10);
        assertEq(MathUtils.abs(-10), 10);
        assertEq(MathUtils.abs(0), 0);
    }

    function testCompound() public {
        uint256 result = MathUtils.compound(1000, 500, 2); // 5% for 2 periods
        assertEq(result, 1102); // 1000 * 1.05 * 1.05 = 1102.5, rounded down
    }

    function testPercentage() public {
        assertEq(MathUtils.percentage(1000, 500), 50); // 5% of 1000
        assertEq(MathUtils.percentage(2000, 1000), 200); // 10% of 2000
        assertEq(MathUtils.percentage(100, 10000), 100); // 100% of 100
    }

    function testSqrt() public {
        assertEq(MathUtils.sqrt(0), 0);
        assertEq(MathUtils.sqrt(1), 1);
        assertEq(MathUtils.sqrt(4), 2);
        assertEq(MathUtils.sqrt(9), 3);
        assertEq(MathUtils.sqrt(16), 4);
        assertEq(MathUtils.sqrt(100), 10);
    }
}
