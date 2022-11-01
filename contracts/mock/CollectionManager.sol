// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MockERC721.sol";
import "./MockERC1155.sol";
import "./CollectionEnumerable.sol";

contract CollectionManager is CollectionEnumerable {
    using Counters for Counters.Counter;
    Counters.Counter public collectionIds;

    mapping(uint256 => NftCollection) private idToNftCollection;
    mapping(string => uint256) private shortUrlToCollectionId;
    mapping(uint256 => address) public collectionToCreator;
    mapping(address => uint256[]) public creatorToCollection;

    event TokenMinted(uint256 indexed tokenId, string tokenURI);

    event CollectionCreated(
        uint256 indexed collectionId,
        uint8 indexed nftType,
        address indexed nftContract,
        string name,
        string symbol,
        string uri,
        address creator
    );

    event CollectionUpdated(
        uint256 indexed collectionId,
        uint8 indexed nftType,
        address indexed nftContract,
        string name,
        string symbol,
        string uri,
        uint8 status,
        address creator
    );

    address private thorContractAddress;

    modifier onlyCreatorOf(uint256 collectionId) {
        require(msg.sender == collectionToCreator[collectionId], "no creator");
        _;
    }

    // _thorContractAddress - an address of thorNode Collection(odin, thor, freya, heimdall)
    // default addressZero
    function createThorCollection(
        string memory name,
        string memory symbol,
        string memory shorturl,
        string memory uri,
        address _thorContractAddress
    ) external {
        thorContractAddress = _thorContractAddress;
        createCollection(2, name, symbol, shorturl, uri);
    }

    /**
     * Create Collection
     *
     * @param nftType - 0: ERC721, 1: ERC1155, 2: ThorNodeNFT
     * @param name - ex: "Zombie Monkeys"
     * @param symbol - ex: "ZmBM"
     * @param uri - ex: "https://ipfs.io/ipfs/QmNyzmjaJ8E8BF4vNWXiJZjEM5ASoFPmrhdoShSYnEdXHQ"
     *
     * returns null
     */
    function createCollection(
        uint8 nftType,
        string memory name,
        string memory symbol,
        string memory shorturl,
        string memory uri
    ) public onlyNftType(nftType) {
        require(bytes(name).length > 0, "name should be not empty");
        require(bytes(symbol).length > 0, "symbol should be not empty");
        require(bytes(uri).length > 0, "uri should be not empty");

        collectionIds.increment();
        uint256 collectionId = collectionIds.current();
        for (uint256 i = 0; i < collectionId - 1; i++) {
            require(!compareStrings(idToNftCollection[i + 1].name, name), "The name is already taken");
            require(!compareStrings(idToNftCollection[i + 1].symbol, symbol), "The symbol is already taken");
            require(!compareStrings(idToNftCollection[i + 1].shorturl, shorturl), "The shorturl is already taken");
        }

        if (nftType == uint8(NftType.ERC721)) {
            MockERC721 contractAddress = new MockERC721(name, symbol);
            idToNftCollection[collectionId] = NftCollection(
                collectionId,
                name,
                symbol,
                shorturl,
                uri,
                nftType,
                uint8(CollectionStatus.NORMAL),
                true,
                address(contractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(contractAddress), name, symbol, uri, msg.sender);
        } else if (nftType == uint8(NftType.ERC1155)) {
            MockERC1155 contractAddress = new MockERC1155(name, symbol, uri);
            idToNftCollection[collectionId] = NftCollection(
                collectionId,
                name,
                symbol,
                shorturl,
                uri,
                nftType,
                uint8(CollectionStatus.NORMAL),
                true,
                address(contractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(contractAddress), name, symbol, uri, msg.sender);
        } else if (nftType == uint8(NftType.ThorNodeNFT)) {
            idToNftCollection[collectionId] = NftCollection(
                collectionId,
                name,
                symbol,
                shorturl,
                uri,
                nftType,
                uint8(CollectionStatus.NORMAL),
                false,
                address(thorContractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(thorContractAddress), name, symbol, uri, msg.sender);
        }

        shortUrlToCollectionId[shorturl] = collectionId;
        collectionToCreator[collectionId] = msg.sender;
        creatorToCollection[msg.sender].push(collectionId);
    }

    /**
     * create NFT
     *
     * @param collectionId - 1, 2, 3...
     * @param amountForErc1155 - default 0(case ERC721), amount minted(case ERC1155)
     *
     * returns null
     */
    function createNFT(
        uint256 collectionId,
        address ownerAddress,
        string memory nftURI,
        uint256 amountForErc1155
    ) external onlyCreatorOf(collectionId) returns (uint256 tokenId) {
        require(collectionId > 0 && collectionId <= collectionIds.current(), "Collection not exist");
        NftCollection memory nftCollection = idToNftCollection[collectionId];
        if (nftCollection.nftType == uint8(NftType.ERC721)) {
            MockERC721 mockERC721 = MockERC721(nftCollection.nftContract);
            uint256 newTokenId = mockERC721.mint(ownerAddress, nftURI);
            emit TokenMinted(newTokenId, nftURI);
            return newTokenId;
        } else if (nftCollection.nftType == uint8(NftType.ERC1155)) {
            MockERC1155 mockERC1155 = MockERC1155(nftCollection.nftContract);
            uint256 newTokenId = mockERC1155.mint(ownerAddress, nftURI, amountForErc1155);
            emit TokenMinted(newTokenId, nftURI);
            return newTokenId;
        }
    }

    function fetchCollectionByCollectionId(uint256 collectionId) public view returns (NftCollection memory) {
        require(collectionId > 0 && collectionId <= collectionIds.current(), "Collection not exist");
        return idToNftCollection[collectionId];
    }

    function fetchCollectionByShorturl(string memory shorturl) public view returns (NftCollection memory, bool) {
        uint256 collectionId = shortUrlToCollectionId[shorturl];
        if (collectionId == 0) {
            NftCollection memory emptyNftCollection;
            return (emptyNftCollection, false);
        }
        return (idToNftCollection[collectionId], true);
    }

    function fetchMyCollectionIds() public view returns (uint256[] memory) {
        return fetchCollectionIdsByCreator(msg.sender);
    }

    function fetchCollectionIdsByCreator(address target) public view returns (uint256[] memory) {
        require(target != address(0), "address to the zero address");
        return creatorToCollection[target];
    }

    // functionalities

    /**
     * update metadata
     */
    function _emitCollectionUpdated(uint256 collectionId) internal {
        emit CollectionUpdated(
            collectionId,
            idToNftCollection[collectionId].nftType,
            idToNftCollection[collectionId].nftContract,
            idToNftCollection[collectionId].name,
            idToNftCollection[collectionId].symbol,
            idToNftCollection[collectionId].uri,
            idToNftCollection[collectionId].status,
            idToNftCollection[collectionId].creator
        );
    }

    function updateName(uint256 collectionId, string memory name) external onlyCreatorOf(collectionId) {
        require(collectionId > 0 && collectionId <= collectionIds.current(), "Collection not exist");
        require(bytes(name).length > 0, "name should be not empty");
        idToNftCollection[collectionId].name = name;

        _emitCollectionUpdated(collectionId);
    }

    function updateSymbol(uint256 collectionId, string memory symbol) external onlyCreatorOf(collectionId) {
        require(collectionId > 0 && collectionId <= collectionIds.current(), "Collection not exist");
        require(bytes(symbol).length > 0, "symbol should be not empty");
        idToNftCollection[collectionId].symbol = symbol;

        _emitCollectionUpdated(collectionId);
    }

    function updateCollectionUri(uint256 collectionId, string memory uri) external onlyCreatorOf(collectionId) {
        require(collectionId > 0 && collectionId <= collectionIds.current(), "Collection not exist");
        require(bytes(uri).length > 0, "collection uri should be not empty");
        idToNftCollection[collectionId].uri = uri;
        _emitCollectionUpdated(collectionId);
    }

    function updateCollectionStatus(uint256 collectionId, uint8 status) external onlyCollectionStatus(status) {
        require(collectionId > 0 && collectionId <= collectionIds.current(), "Collection not exist");
        idToNftCollection[collectionId].status = status;
        _emitCollectionUpdated(collectionId);
    }
}
