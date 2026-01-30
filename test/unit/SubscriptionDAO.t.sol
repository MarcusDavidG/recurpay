// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/dao/SubscriptionDAO.sol";

contract SubscriptionDAOTest is Test {
    SubscriptionDAO dao;
    address member1 = address(0x1);
    address member2 = address(0x2);

    function setUp() public {
        dao = new SubscriptionDAO();
        dao.addMember(member1, 1000);
        dao.addMember(member2, 500);
    }

    function testCreateProposal() public {
        vm.prank(member1);
        uint256 proposalId = dao.createProposal("Test proposal");
        
        assertEq(proposalId, 1);
        
        (uint256 id, address proposer, string memory description, uint256 votesFor, uint256 votesAgainst, uint256 endTime, bool executed) = dao.proposals(proposalId);
        assertEq(id, 1);
        assertEq(proposer, member1);
        assertEq(description, "Test proposal");
        assertEq(votesFor, 0);
        assertEq(votesAgainst, 0);
        assertFalse(executed);
    }

    function testVoting() public {
        vm.prank(member1);
        uint256 proposalId = dao.createProposal("Test proposal");
        
        vm.prank(member1);
        dao.vote(proposalId, true);
        
        vm.prank(member2);
        dao.vote(proposalId, false);
        
        (, , , uint256 votesFor, uint256 votesAgainst, ,) = dao.proposals(proposalId);
        assertEq(votesFor, 1000);
        assertEq(votesAgainst, 500);
    }

    function testExecuteProposal() public {
        vm.prank(member1);
        uint256 proposalId = dao.createProposal("Test proposal");
        
        vm.prank(member1);
        dao.vote(proposalId, true);
        
        vm.warp(block.timestamp + 7 days + 1);
        
        dao.executeProposal(proposalId);
        
        (, , , , , , bool executed) = dao.proposals(proposalId);
        assertTrue(executed);
    }
}
