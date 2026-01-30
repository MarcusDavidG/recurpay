// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionNFT {
    struct NFTSubscription {
        uint256 tokenId;
        address subscriber;
        uint256 planId;
        uint256 expiresAt;
        bool active;
        string metadataURI;
    }

    mapping(uint256 => NFTSubscription) public nftSubscriptions;
    mapping(address => uint256[]) public userNFTs;
    uint256 public nextTokenId = 1;

    event NFTSubscriptionMinted(uint256 indexed tokenId, address subscriber, uint256 planId);
    event NFTSubscriptionExpired(uint256 indexed tokenId);

    function mintSubscriptionNFT(
        address subscriber,
        uint256 planId,
        uint256 duration,
        string memory metadataURI
    ) external returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        
        nftSubscriptions[tokenId] = NFTSubscription({
            tokenId: tokenId,
            subscriber: subscriber,
            planId: planId,
            expiresAt: block.timestamp + duration,
            active: true,
            metadataURI: metadataURI
        });

        userNFTs[subscriber].push(tokenId);
        emit NFTSubscriptionMinted(tokenId, subscriber, planId);
    }

    function isNFTActive(uint256 tokenId) external view returns (bool) {
        NFTSubscription memory nft = nftSubscriptions[tokenId];
        return nft.active && block.timestamp <= nft.expiresAt;
    }

    function expireNFT(uint256 tokenId) external {
        NFTSubscription storage nft = nftSubscriptions[tokenId];
        require(block.timestamp > nft.expiresAt, "Not expired");
        
        nft.active = false;
        emit NFTSubscriptionExpired(tokenId);
    }

    function getUserNFTs(address user) external view returns (uint256[] memory) {
        return userNFTs[user];
    }
}
