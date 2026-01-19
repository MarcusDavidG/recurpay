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
        uint256 bps = 10001; // &gt; 100%

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
