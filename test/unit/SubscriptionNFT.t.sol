// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/nft/SubscriptionNFT.sol";

contract SubscriptionNFTTest is Test {
    SubscriptionNFT nft;
    address creator = address(0x1);
    address subscriber = address(0x2);

    function setUp() public {
        nft = new SubscriptionNFT();
    }

    function testMintNFT() public {
        uint256 tokenId = nft.mintSubscriptionNFT(
            subscriber,
            1,
            30 days,
            "ipfs://metadata"
        );

        assertEq(tokenId, 1);
        assertTrue(nft.isNFTActive(tokenId));
        
        uint256[] memory userNFTs = nft.getUserNFTs(subscriber);
        assertEq(userNFTs.length, 1);
        assertEq(userNFTs[0], tokenId);
    }

    function testNFTExpiration() public {
        uint256 tokenId = nft.mintSubscriptionNFT(
            subscriber,
            1,
            30 days,
            "ipfs://metadata"
        );

        assertTrue(nft.isNFTActive(tokenId));
        
        vm.warp(block.timestamp + 31 days);
        assertFalse(nft.isNFTActive(tokenId));
        
        nft.expireNFT(tokenId);
        (,,,, bool active,) = nft.nftSubscriptions(tokenId);
        assertFalse(active);
    }

    function testMultipleNFTs() public {
        uint256 tokenId1 = nft.mintSubscriptionNFT(subscriber, 1, 30 days, "ipfs://1");
        uint256 tokenId2 = nft.mintSubscriptionNFT(subscriber, 2, 60 days, "ipfs://2");

        uint256[] memory userNFTs = nft.getUserNFTs(subscriber);
        assertEq(userNFTs.length, 2);
        assertTrue(nft.isNFTActive(tokenId1));
        assertTrue(nft.isNFTActive(tokenId2));
    }
}
