// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @author: magni

/**
 * @dev Lookup engine interface
 */
interface ICollectionManager {
    struct NftCollection {
        uint8 nftType;
        uint8 status;
        uint256 collectionId;
        string name;
        string symbol;
        string shorturl;
        string uri;
        bool isExternalCollection;
        address nftAddress;
        address creator;
    }

    event TokenMinted(uint256 indexed tokenId, string tokenURI);

    event CollectionCreated(
        uint256 indexed collectionId,
        uint8 indexed nftType,
        address indexed nftAddress,
        string name,
        string symbol,
        string uri
    );

    event CollectionUpdated(
        uint256 indexed collectionId,
        uint8 indexed nftType,
        address indexed nftAddress,
        string name,
        string symbol,
        string uri,
        uint8 status
    );

    /**
     * Create Collection
     *
     * @param nftType - 0: ERC721, 1: ERC1155, 2: ThorNodeNFT
     * @param name - ex: "Zombie Monkeys"
     * @param symbol - ex: "ZmBM"
     * @param shorturl - ex: "zombiemonkeys" it should not contain '/'
     * @param uri - ex: "https://ipfs.io/ipfs/QmNyzmjaJ8E8BF4vNWXiJZjEM5ASoFPmrhdoShSYnEdXHQ"
     *              uri contains metadata including image, category, or description.
     *
     * returns null
     */
    function createCollection(
        uint8 nftType,
        string memory name,
        string memory symbol,
        string memory shorturl,
        string memory uri
    ) external;

    /**
     * Create Thor Collection(odin, thor, freya, heimdall)
     *
     * @param _thorContractAddress - an address of thorNode Collection(odin, thor, freya, heimdall)
     *
     * returns null
     */

    function createThorCollection(
        string memory name,
        string memory symbol,
        string memory shorturl,
        string memory uri,
        address _thorContractAddress
    ) external;

    /**
     * create NFT
     *
     * @param collectionId - collectionId of NFT, it will define ERC721, ERC721 or Thor Node
     * @param ownerAddress - Owner Address of NFT
     * @param nftURI - ex: https://ipfs.io/ipfs/Qma1wY9HLfdWbRr1tDPpVCfbtPPvjnai1rEukuqSxk6PWb
     *                 NFT metadata, it can contain NFT image, 'Display Name', 'Symbol', 'shortURL', 'Category'
     * @param amountForErc1155 - default 0(case ERC721), amount minted(case ERC1155)
     *
     * returns null
     */
    function createNFT(
        uint256 collectionId,
        address ownerAddress,
        string memory nftURI,
        uint256 amountForErc1155
    ) external;

    function fetchCollectionByCollectionId(uint256 collectionId) external returns (NftCollection memory);

    function fetchCollectionByShorturl(string memory shorturl) external returns (NftCollection memory, bool);

    function fetchCollectionIdsByCreator(address target) external returns (uint256[] memory);

    function updateName(uint256 collectionId, string memory name) external;

    function updateSymbol(uint256 collectionId, string memory symbol) external;

    function updateCollectionUri(uint256 collectionId, string memory uri) external;

    function updateCollectionStatus(uint256 collectionId, uint8 status) external;
}
