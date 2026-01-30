// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/routing/SubscriptionRouter.sol";
import "../../src/v2/SubscriptionFactory2.sol";

contract SubscriptionRouterIntegrationTest is Test {
    SubscriptionRouter router;
    SubscriptionFactory2 factory;
    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        vm.prank(owner);
        router = new SubscriptionRouter();
        
        factory = new SubscriptionFactory2();
        
        vm.prank(owner);
        router.setContract("factory", address(factory));
        
        vm.prank(owner);
        router.authorize(user);
    }

    function testRouteToFactory() public {
        bytes memory data = abi.encodeWithSignature("createPlan(uint256,uint256)", 1 ether, 30 days);
        
        vm.prank(user);
        bytes memory result = router.route("factory", data);
        
        uint256 planId = abi.decode(result, (uint256));
        assertEq(planId, 1);
    }

    function testBatchRoute() public {
        string[] memory contractNames = new string[](2);
        contractNames[0] = "factory";
        contractNames[1] = "factory";
        
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("createPlan(uint256,uint256)", 1 ether, 30 days);
        data[1] = abi.encodeWithSignature("createPlan(uint256,uint256)", 2 ether, 60 days);
        
        vm.prank(user);
        bytes[] memory results = router.batchRoute(contractNames, data);
        
        assertEq(results.length, 2);
        
        uint256 planId1 = abi.decode(results[0], (uint256));
        uint256 planId2 = abi.decode(results[1], (uint256));
        
        assertEq(planId1, 1);
        assertEq(planId2, 2);
    }

    function testFailUnauthorizedRoute() public {
        bytes memory data = abi.encodeWithSignature("createPlan(uint256,uint256)", 1 ether, 30 days);
        
        vm.expectRevert("Not authorized");
        router.route("factory", data);
    }

    function testFailInvalidContract() public {
        bytes memory data = abi.encodeWithSignature("createPlan(uint256,uint256)", 1 ether, 30 days);
        
        vm.prank(user);
        vm.expectRevert("Contract not found");
        router.route("invalid", data);
    }
}
