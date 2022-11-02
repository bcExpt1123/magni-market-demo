// SPDX-License-Identifier: MIT
/// @author: magni

pragma solidity ^0.8.9;

contract CollectionEnumerable {
    enum MarketType {
        FIXED,
        AUCTION
    }

    enum NftType {
        ERC721,
        ERC1155,
        ThorNodeNFT
    }

    enum CollectionStatus {
        NORMAL,
        BANNED,
        REMOVED,
        OTHERS
    }

    enum PaymentMethod {
        AVAX,
        ERC20
    }

    struct NftCollection {
        uint256 collectionId;
        string name;
        string symbol;
        string shorturl;
        string uri;
        uint8 nftType;
        uint8 status;
        bool isExternalCollection;
        address nftAddress;
        address creator;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    modifier onlyNftType(uint8 nftType) {
        require(
            nftType == uint8(NftType.ERC721) ||
                nftType == uint8(NftType.ERC1155) ||
                nftType == uint8(NftType.ThorNodeNFT),
            "Nft type should be ERC721, ERC1155 or ThorNodeNFT"
        );
        _;
    }

    modifier onlyCollectionStatus(uint8 status) {
        require(
            status == uint8(CollectionStatus.NORMAL) ||
                status == uint8(CollectionStatus.BANNED) ||
                status == uint8(CollectionStatus.REMOVED) ||
                status == uint8(CollectionStatus.OTHERS),
            "Collection Status should be NORMAL, BANNED, REMOVED, or OTHERS"
        );
        _;
    }
}
