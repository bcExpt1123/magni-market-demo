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
    mapping(uint256 => address) public collectionToOwner;
    mapping(address => uint256[]) public ownerToCollection;
    mapping(uint256 => string) public collectionURI;

    event CollectionCreated(
        uint256 indexed collectionId,
        uint8 indexed nftType,
        address nftContract,
        string name,
        string symbol,
        string uri,
        address owner
    );

    event CollectionUpdated(
        uint256 indexed collectionId,
        uint8 indexed nftType,
        address nftContract,
        string name,
        string symbol,
        string uri,
        uint8 status,
        address owner
    );

    address private thorContractAddress;

    modifier onlyOwnerOf(uint256 collectionId) {
        require(msg.sender == collectionToOwner[collectionId], "no owner");
        _;
    }

    // _thorContractAddress - an address of thorNode Collection(odin, thor, freya, heimdall)
    // default addressZero
    function createThorCollection(
        string memory name,
        string memory symbol,
        string memory uri,
        address _thorContractAddress
    ) external {
        thorContractAddress = _thorContractAddress;
        createCollection(2, name, symbol, uri);
    }

    /**
     * Create Collection
     *
     * @param nftType - 0: ERC721, 1: ERC1155, 2: ThorNodeNFT
     * @param name - ex: "Zombie Monkeys"
     * @param symbol - ex: "ZmBM"
     * @param uri - ex: "https://testnets-api.opensea.io/api/v1/assets?collection=zombiemonkeys"
     *
     * returns null
     */
    function createCollection(
        uint8 nftType,
        string memory name,
        string memory symbol,
        string memory uri
    ) public onlyNftType(nftType) {
        require(bytes(name).length > 0, "name should be not empty");
        require(bytes(symbol).length > 0, "symbol should be not empty");
        require(bytes(uri).length > 0, "uri should be not empty");

        uint256 collectionId = collectionIds.current();
        for (uint256 i = 0; i < collectionId; i++) {
            require(!compareStrings(idToNftCollection[i].name, name), "The name is already taken");
        }

        collectionIds.increment();

        if (nftType == uint8(NftType.ERC721)) {
            MockERC721 contractAddress = new MockERC721(name, symbol);
            idToNftCollection[collectionId] = NftCollection(
                name,
                symbol,
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
                name,
                symbol,
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
                name,
                symbol,
                uri,
                nftType,
                uint8(CollectionStatus.NORMAL),
                false,
                address(thorContractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(thorContractAddress), name, symbol, uri, msg.sender);
        }

        collectionURI[collectionId] = uri;
        collectionToOwner[collectionId] = msg.sender;
        ownerToCollection[msg.sender].push(collectionId);
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
        string memory tokenURI,
        uint256 amountForErc1155
    ) external onlyOwnerOf(collectionId) {
        require(collectionId < collectionIds.current(), "Collection not exist");
        NftCollection memory nftCollection = idToNftCollection[collectionId];
        if (nftCollection.nftType == uint8(NftType.ERC721)) {
            MockERC721 mockERC721 = MockERC721(nftCollection.nftContract);
            mockERC721.mint(ownerAddress, tokenURI);
        } else if (nftCollection.nftType == uint8(NftType.ERC1155)) {
            MockERC1155 mockERC1155 = MockERC1155(nftCollection.nftContract);
            mockERC1155.mint(ownerAddress, tokenURI, amountForErc1155);
        }
    }

    function fetchByCollectionId(uint256 collectionId) public view returns (NftCollection memory) {
        require(collectionId < collectionIds.current(), "Collection not exist");
        return idToNftCollection[collectionId];
    }

    function fetchMyCollectionIds() public view returns (uint256[] memory) {
        return fetchCollectionIdsByOwner(msg.sender);
    }

    function fetchCollectionIdsByOwner(address target) public view returns (uint256[] memory) {
        require(target != address(0), "address to the zero address");
        return ownerToCollection[target];
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
            idToNftCollection[collectionId].owner
        );
    }

    function updateName(uint256 collectionId, string memory name) external onlyOwnerOf(collectionId) {
        require(collectionId < collectionIds.current(), "Collection not exist");
        require(bytes(name).length > 0, "name should be not empty");
        idToNftCollection[collectionId].name = name;

        _emitCollectionUpdated(collectionId);
    }

    function updateSymbol(uint256 collectionId, string memory symbol) external onlyOwnerOf(collectionId) {
        require(collectionId < collectionIds.current(), "Collection not exist");
        require(bytes(symbol).length > 0, "symbol should be not empty");
        idToNftCollection[collectionId].symbol = symbol;

        _emitCollectionUpdated(collectionId);
    }

    function updateTokenUri(uint256 collectionId, string memory tokenuri) external onlyOwnerOf(collectionId) {
        require(collectionId < collectionIds.current(), "Collection not exist");
        require(bytes(tokenuri).length > 0, "token uri should be not empty");
        idToNftCollection[collectionId].uri = tokenuri;
        _emitCollectionUpdated(collectionId);
    }

    function updateCollectionStatus(uint256 collectionId, uint8 status) external onlyCollectionStatus(status) {
        require(collectionId < collectionIds.current(), "Collection not exist");
        idToNftCollection[collectionId].status = status;
        _emitCollectionUpdated(collectionId);
    }
}
