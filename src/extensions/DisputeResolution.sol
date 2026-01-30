// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DisputeResolution {
    enum DisputeStatus {
        PENDING,
        UNDER_REVIEW,
        RESOLVED,
        REJECTED,
        ESCALATED
    }

    enum DisputeType {
        BILLING_ERROR,
        SERVICE_NOT_DELIVERED,
        UNAUTHORIZED_CHARGE,
        QUALITY_ISSUE,
        CANCELLATION_DISPUTE,
        OTHER
    }

    struct Dispute {
        uint256 id;
        address subscriber;
        address creator;
        bytes32 subscriptionId;
        DisputeType disputeType;
        DisputeStatus status;
        uint256 amount;
        string description;
        string resolution;
        uint256 createdAt;
        uint256 resolvedAt;
        address resolver;
        bool refundIssued;
        uint256 refundAmount;
    }

    struct Evidence {
        address submitter;
        string description;
        bytes32 evidenceHash;
        uint256 submittedAt;
    }

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => Evidence[]) public disputeEvidence;
    mapping(address => uint256[]) public userDisputes;
    mapping(address => uint256[]) public creatorDisputes;
    mapping(address => bool) public authorizedResolvers;
    
    uint256 public disputeCounter;
    uint256 public constant DISPUTE_TIMEOUT = 30 days;
    address public admin;

    event DisputeCreated(uint256 indexed disputeId, address indexed subscriber, address indexed creator);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status, uint256 refundAmount);
    event DisputeEscalated(uint256 indexed disputeId, address indexed resolver);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyAuthorizedResolver() {
        require(authorizedResolvers[msg.sender] || msg.sender == admin, "Not authorized resolver");
        _;
    }

    constructor() {
        admin = msg.sender;
        authorizedResolvers[msg.sender] = true;
    }

    function createDispute(
        address creator,
        bytes32 subscriptionId,
        DisputeType disputeType,
        uint256 amount,
        string memory description
    ) external returns (uint256 disputeId) {
        disputeId = ++disputeCounter;

        disputes[disputeId] = Dispute({
            id: disputeId,
            subscriber: msg.sender,
            creator: creator,
            subscriptionId: subscriptionId,
            disputeType: disputeType,
            status: DisputeStatus.PENDING,
            amount: amount,
            description: description,
            resolution: "",
            createdAt: block.timestamp,
            resolvedAt: 0,
            resolver: address(0),
            refundIssued: false,
            refundAmount: 0
        });

        userDisputes[msg.sender].push(disputeId);
        creatorDisputes[creator].push(disputeId);

        emit DisputeCreated(disputeId, msg.sender, creator);
    }

    function submitEvidence(
        uint256 disputeId,
        string memory description,
        bytes32 evidenceHash
    ) external {
        Dispute memory dispute = disputes[disputeId];
        require(
            msg.sender == dispute.subscriber || msg.sender == dispute.creator,
            "Not authorized to submit evidence"
        );
        require(dispute.status == DisputeStatus.PENDING || dispute.status == DisputeStatus.UNDER_REVIEW, "Dispute not active");

        disputeEvidence[disputeId].push(Evidence({
            submitter: msg.sender,
            description: description,
            evidenceHash: evidenceHash,
            submittedAt: block.timestamp
        }));

        // Update status to under review if it was pending
        if (dispute.status == DisputeStatus.PENDING) {
            disputes[disputeId].status = DisputeStatus.UNDER_REVIEW;
        }

        emit EvidenceSubmitted(disputeId, msg.sender);
    }

    function resolveDispute(
        uint256 disputeId,
        DisputeStatus resolution,
        uint256 refundAmount,
        string memory resolutionDescription
    ) external onlyAuthorizedResolver {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.status == DisputeStatus.UNDER_REVIEW, "Dispute not under review");
        require(resolution == DisputeStatus.RESOLVED || resolution == DisputeStatus.REJECTED, "Invalid resolution");

        dispute.status = resolution;
        dispute.resolution = resolutionDescription;
        dispute.resolvedAt = block.timestamp;
        dispute.resolver = msg.sender;

        if (resolution == DisputeStatus.RESOLVED && refundAmount > 0) {
            dispute.refundIssued = true;
            dispute.refundAmount = refundAmount;
            
            // Issue refund (simplified - would integrate with payment system)
            (bool success, ) = payable(dispute.subscriber).call{value: refundAmount}("");
            require(success, "Refund failed");
        }

        emit DisputeResolved(disputeId, resolution, refundAmount);
    }

    function escalateDispute(uint256 disputeId) external {
        Dispute storage dispute = disputes[disputeId];
        require(
            msg.sender == dispute.subscriber || msg.sender == dispute.creator,
            "Not authorized to escalate"
        );
        require(dispute.status == DisputeStatus.UNDER_REVIEW, "Cannot escalate");
        require(block.timestamp >= dispute.createdAt + 7 days, "Too early to escalate");

        dispute.status = DisputeStatus.ESCALATED;

        emit DisputeEscalated(disputeId, msg.sender);
    }

    function autoResolveExpiredDisputes(uint256[] memory disputeIds) external {
        for (uint256 i = 0; i < disputeIds.length; i++) {
            Dispute storage dispute = disputes[disputeIds[i]];
            
            if (dispute.status == DisputeStatus.PENDING && 
                block.timestamp >= dispute.createdAt + DISPUTE_TIMEOUT) {
                
                dispute.status = DisputeStatus.REJECTED;
                dispute.resolution = "Auto-resolved due to timeout";
                dispute.resolvedAt = block.timestamp;
                
                emit DisputeResolved(disputeIds[i], DisputeStatus.REJECTED, 0);
            }
        }
    }

    function addAuthorizedResolver(address resolver) external onlyAdmin {
        authorizedResolvers[resolver] = true;
    }

    function removeAuthorizedResolver(address resolver) external onlyAdmin {
        authorizedResolvers[resolver] = false;
    }

    function getDispute(uint256 disputeId) external view returns (Dispute memory) {
        return disputes[disputeId];
    }

    function getDisputeEvidence(uint256 disputeId) external view returns (Evidence[] memory) {
        return disputeEvidence[disputeId];
    }

    function getUserDisputes(address user) external view returns (uint256[] memory) {
        return userDisputes[user];
    }

    function getCreatorDisputes(address creator) external view returns (uint256[] memory) {
        return creatorDisputes[creator];
    }

    function getPendingDisputes() external view returns (uint256[] memory pending) {
        // This would return all pending disputes
        // Simplified implementation
        uint256[] memory pendingDisputes = new uint256[](0);
        return pendingDisputes;
    }

    function getDisputesByStatus(DisputeStatus status) external view returns (uint256[] memory) {
        // This would return all disputes with specific status
        // Simplified implementation
        uint256[] memory statusDisputes = new uint256[](0);
        return statusDisputes;
    }

    function isDisputeExpired(uint256 disputeId) external view returns (bool) {
        Dispute memory dispute = disputes[disputeId];
        return dispute.status == DisputeStatus.PENDING && 
               block.timestamp >= dispute.createdAt + DISPUTE_TIMEOUT;
    }
}
