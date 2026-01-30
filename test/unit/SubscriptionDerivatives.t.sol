// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/derivatives/SubscriptionDerivatives.sol";

contract SubscriptionDerivativesTest is Test {
    SubscriptionDerivatives derivatives;
    address creator = address(0x1);
    address buyer = address(0x2);

    function setUp() public {
        derivatives = new SubscriptionDerivatives();
        vm.deal(buyer, 10 ether);
    }

    function testCreateCallDerivative() public {
        vm.prank(creator);
        bytes32 derivativeId = derivatives.createDerivative(
            SubscriptionDerivatives.DerivativeType.CALL,
            1,
            1 ether,
            0.1 ether,
            30 days
        );

        (
            SubscriptionDerivatives.DerivativeType derivativeType,
            address derivativeCreator,
            address derivativeBuyer,
            uint256 subscriptionId,
            uint256 strikePrice,
            uint256 premium,
            uint256 expiryTime,
            bool exercised,
            bool settled
        ) = derivatives.derivatives(derivativeId);

        assertEq(uint8(derivativeType), uint8(SubscriptionDerivatives.DerivativeType.CALL));
        assertEq(derivativeCreator, creator);
        assertEq(subscriptionId, 1);
        assertEq(strikePrice, 1 ether);
        assertEq(premium, 0.1 ether);
        assertFalse(exercised);
        assertFalse(settled);
    }

    function testBuyDerivative() public {
        vm.prank(creator);
        bytes32 derivativeId = derivatives.createDerivative(
            SubscriptionDerivatives.DerivativeType.CALL,
            1,
            1 ether,
            0.1 ether,
            30 days
        );

        vm.prank(buyer);
        derivatives.buyDerivative{value: 0.1 ether}(derivativeId);

        (, , address derivativeBuyer, , , , , ,) = derivatives.derivatives(derivativeId);
        assertEq(derivativeBuyer, buyer);
    }

    function testExerciseDerivative() public {
        vm.prank(creator);
        bytes32 derivativeId = derivatives.createDerivative(
            SubscriptionDerivatives.DerivativeType.CALL,
            1,
            1 ether,
            0.1 ether,
            30 days
        );

        vm.prank(buyer);
        derivatives.buyDerivative{value: 0.1 ether}(derivativeId);

        vm.prank(buyer);
        derivatives.exerciseDerivative{value: 1 ether}(derivativeId);

        (, , , , , , , bool exercised,) = derivatives.derivatives(derivativeId);
        assertTrue(exercised);
    }
}
