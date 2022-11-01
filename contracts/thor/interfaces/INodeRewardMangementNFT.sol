// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INodeRewardManagementNFT {

    struct NodeMeta {
        address owner;
        string name;
        string metadata;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}
