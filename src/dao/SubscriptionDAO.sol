// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionDAO {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    struct Member {
        uint256 votingPower;
        uint256 joinedAt;
        bool active;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(address => uint256[]) public memberProposals;
    
    uint256 public proposalCounter;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant MIN_VOTING_POWER = 100;

    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 power);
    event MemberAdded(address member, uint256 votingPower);

    function addMember(address member, uint256 votingPower) external {
        members[member] = Member({
            votingPower: votingPower,
            joinedAt: block.timestamp,
            active: true
        });
        emit MemberAdded(member, votingPower);
    }

    function createProposal(string memory description) external returns (uint256 proposalId) {
        require(members[msg.sender].active, "Not a member");
        require(members[msg.sender].votingPower >= MIN_VOTING_POWER, "Insufficient voting power");
        
        proposalId = ++proposalCounter;
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.endTime = block.timestamp + VOTING_PERIOD;

        memberProposals[msg.sender].push(proposalId);
        emit ProposalCreated(proposalId, msg.sender);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(members[msg.sender].active, "Not a member");

        uint256 power = members[msg.sender].votingPower;
        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor += power;
        } else {
            proposal.votesAgainst += power;
        }

        emit VoteCast(proposalId, msg.sender, support, power);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal failed");

        proposal.executed = true;
        // Execute proposal logic here
    }
}
