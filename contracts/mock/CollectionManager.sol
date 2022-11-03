// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "./MockERC721.sol";
import "./MockERC1155.sol";
import "./CollectionEnumerable.sol";
import "../interfaces/ICollectionManager.sol";

contract CollectionManager is CollectionEnumerable, ICollectionManager {
    using Counters for Counters.Counter;
    Counters.Counter public collectionIds;

    mapping(uint256 => NftCollection) private idToNftCollection;
    mapping(string => uint256) private shortUrlToCollectionId;
    mapping(uint256 => address) public collectionToCreator;
    mapping(address => uint256[]) public creatorToCollection;

    address private thorContractAddress;

    modifier onlyCreatorOf(uint256 collectionId) {
        require(msg.sender == collectionToCreator[collectionId], "no creator");
        _;
    }

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

    function createCollection(
        uint8 nftType,
        string memory name,
        string memory symbol,
        string memory shorturl,
        string memory uri
    ) public override onlyNftType(nftType) {
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
                nftType,
                uint8(CollectionStatus.NORMAL),
                collectionId,
                name,
                symbol,
                shorturl,
                uri,
                true,
                address(contractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(contractAddress), name, symbol, uri);
        } else if (nftType == uint8(NftType.ERC1155)) {
            MockERC1155 contractAddress = new MockERC1155(name, symbol, uri);
            idToNftCollection[collectionId] = NftCollection(
                nftType,
                uint8(CollectionStatus.NORMAL),
                collectionId,
                name,
                symbol,
                shorturl,
                uri,
                true,
                address(contractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(contractAddress), name, symbol, uri);
        } else if (nftType == uint8(NftType.ThorNodeNFT)) {
            idToNftCollection[collectionId] = NftCollection(
                nftType,
                uint8(CollectionStatus.NORMAL),
                collectionId,
                name,
                symbol,
                shorturl,
                uri,
                false,
                address(thorContractAddress),
                msg.sender
            );
            emit CollectionCreated(collectionId, nftType, address(thorContractAddress), name, symbol, uri);
        }

        shortUrlToCollectionId[shorturl] = collectionId;
        collectionToCreator[collectionId] = msg.sender;
        creatorToCollection[msg.sender].push(collectionId);
    }

    function createNFT(
        uint256 collectionId,
        address ownerAddress,
        string memory nftURI,
        uint256 amountForErc1155
    ) external override onlyCreatorOf(collectionId) {
        NftCollection memory nftCollection = idToNftCollection[collectionId];
        require(nftCollection.nftType == 0 || nftCollection.nftType == 1, "It can create only ERC721, or ERC1155");
        if (nftCollection.nftType == uint8(NftType.ERC721)) {
            MockERC721 mockERC721 = MockERC721(nftCollection.nftAddress);
            uint256 newTokenId = mockERC721.mint(ownerAddress, nftURI);
            emit TokenMinted(newTokenId, nftURI);
        } else if (nftCollection.nftType == uint8(NftType.ERC1155)) {
            MockERC1155 mockERC1155 = MockERC1155(nftCollection.nftAddress);
            uint256 newTokenId = mockERC1155.mint(ownerAddress, nftURI, amountForErc1155);
            emit TokenMinted(newTokenId, nftURI);
        }
    }

    function fetchCollectionByCollectionId(uint256 collectionId) external view override returns (NftCollection memory) {
        return idToNftCollection[collectionId];
    }

    function fetchCollectionByShorturl(string memory shorturl)
        external
        view
        override
        returns (NftCollection memory, bool)
    {
        uint256 collectionId = shortUrlToCollectionId[shorturl];
        if (collectionId == 0) {
            NftCollection memory emptyNftCollection;
            return (emptyNftCollection, false);
        }
        return (idToNftCollection[collectionId], true);
    }

    function fetchCollectionIdsByCreator(address target) public view override returns (uint256[] memory) {
        return creatorToCollection[target];
    }

    function _emitCollectionUpdated(uint256 collectionId) internal {
        emit CollectionUpdated(
            collectionId,
            idToNftCollection[collectionId].nftType,
            idToNftCollection[collectionId].nftAddress,
            idToNftCollection[collectionId].name,
            idToNftCollection[collectionId].symbol,
            idToNftCollection[collectionId].uri,
            idToNftCollection[collectionId].status
        );
    }

    function updateName(uint256 collectionId, string memory name) external override onlyCreatorOf(collectionId) {
        idToNftCollection[collectionId].name = name;
        _emitCollectionUpdated(collectionId);
    }

    function updateSymbol(uint256 collectionId, string memory symbol) external override onlyCreatorOf(collectionId) {
        idToNftCollection[collectionId].symbol = symbol;
        _emitCollectionUpdated(collectionId);
    }

    function updateCollectionUri(uint256 collectionId, string memory uri)
        external
        override
        onlyCreatorOf(collectionId)
    {
        idToNftCollection[collectionId].uri = uri;
        _emitCollectionUpdated(collectionId);
    }

    function updateCollectionStatus(uint256 collectionId, uint8 status) external override onlyCollectionStatus(status) {
        idToNftCollection[collectionId].status = status;
        _emitCollectionUpdated(collectionId);
    }
}
