// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollectionEnumerable.sol";
// import "./CollectionManager.sol";
import "../interfaces/ICollectionManager.sol";
import "../interfaces/IRoyaltyManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../thor/interfaces/INodeRewardMangementNFT.sol";

contract Marketplace is CollectionEnumerable, ReentrancyGuard, Ownable {
    IRoyaltyManager private royaltyManagerMainnet;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _marketItemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsCanceled;

    ICollectionManager private collectionManager;

    // Challenge: make this price dynamic according to the current currency price
    uint256 private listingFee = 0.025 ether;

    //testnet : 0xb529782800e4a0feac1A01aE410E99E90c4C28AB
    //mainnet : 0x8F47416CaE600bccF9530E9F3aeaA06bdD1Caa79
    ERC20 private thorToken; // = ERC20(thorV2Address);

    constructor(
        address thorV2Address,
        address royaltyManagerAddress,
        address collectionAddress
    ) {
        thorToken = ERC20(thorV2Address);
        royaltyManagerMainnet = IRoyaltyManager(royaltyManagerAddress);
        collectionManager = ICollectionManager(collectionAddress);
    }

    // function updateThorV2Address(address _thorV2Address) public {
    //     thorV2Address = _thorV2Address;
    //     thorToken = ERC20(thorV2Address);
    // }

    struct MarketItem {
        uint8 nftType;
        uint8 paymentMethod;
        uint256 marketItemId;
        uint256 collectionId;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address nftAddress;
        address payable creator;
        address payable seller;
        address payable owner;
        bool sold;
        bool canceled;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint8 indexed nftType,
        uint256 indexed marketItemId,
        uint256 indexed collectionId,
        uint256 tokenId,
        address nftAddress,
        address seller
    );

    event MarketItemSold(uint256 indexed marketItemId, address owner);
    event MarketItemCanceled(
        uint8 indexed nftType,
        uint256 indexed marketItemId,
        uint256 indexed collectionId,
        uint256 tokenId,
        address nftAddress,
        address seller
    );

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function updateListingFee(uint256 _listingFee) public onlyOwner {
        listingFee = _listingFee;
    }

    /**
     * @dev Creates a market item listing, requiring a listing fee and transfering the NFT token from
     * msg.sender to the marketplace contract.
     */
    function createMarketItem(
        uint8 nftType,
        address nftAddress,
        uint256 collectionId,
        uint256 tokenId,
        uint8 paymentMethod,
        uint256 price,
        uint256 amountOfErc1155
    ) public payable nonReentrant onlyNftType(nftType) {
        require(price > 0, "Price must be at least 1 wei");
        // NftCollection memory collection = collectionManager.fetchCollectionByCollectionId(collectionId);
        // require(collection.status == uint8(CollectionStatus.NORMAL), "Collection should be NORMAL");

        if (nftType == uint8(NftType.ERC721)) {
            require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this token");
        } else if (nftType == uint8(NftType.ERC1155)) {
            require(amountOfErc1155 <= IERC1155(nftAddress).balanceOf(msg.sender, tokenId), "balance is not enough");
        } else if (nftType == uint8(NftType.ThorNodeNFT)) {
            require(
                INodeRewardManagementNFT(nftAddress).ownerOf(tokenId) == msg.sender,
                "You are not owner of this token"
            );
        }

        if (paymentMethod == uint8(PaymentMethod.AVAX)) {
            if (nftType == uint8(NftType.ERC721)) {
                require(msg.value == listingFee, "Listing fee must be equal to listing fee of ERC721");
            } else if (nftType == uint8(NftType.ERC1155)) {
                require(
                    msg.value == amountOfErc1155.mul(listingFee),
                    "Listing fee must be equal to listing fee of ERC1155"
                );
            } else if (nftType == uint8(NftType.ThorNodeNFT)) {
                require(msg.value == listingFee, "Listing fee must be equal to listing fee of ThorNodeNFT");
            }
        } else if (paymentMethod == uint8(PaymentMethod.ERC20)) {
            thorToken.transferFrom(msg.sender, address(this), listingFee);
        }

        _marketItemIds.increment();
        uint256 marketItemId = _marketItemIds.current();

        idToMarketItem[marketItemId] = MarketItem(
            nftType,
            paymentMethod,
            marketItemId,
            collectionId,
            tokenId,
            amountOfErc1155,
            price,
            nftAddress,
            payable(msg.sender),
            payable(msg.sender),
            payable(address(0)),
            false,
            false
        );

        if (nftType == uint8(NftType.ERC721)) {
            IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        } else if (nftType == uint8(NftType.ERC1155)) {
            IERC1155(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId, amountOfErc1155, "");
        } else if (nftType == uint8(NftType.ThorNodeNFT)) {
            INodeRewardManagementNFT(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        }

        emit MarketItemCreated(nftType, marketItemId, collectionId, tokenId, nftAddress, msg.sender);
    }

    /**
     * @dev Cancel a market item
     */
    function cancelMarketItem(uint256 marketItemId) public nonReentrant {
        require(marketItemId > 0 && marketItemId <= _marketItemIds.current(), "marketItem not exist");
        address nftAddress = idToMarketItem[marketItemId].nftAddress;
        uint256 tokenId = idToMarketItem[marketItemId].tokenId;
        uint256 collectionId = idToMarketItem[marketItemId].collectionId;
        uint8 nftType = idToMarketItem[marketItemId].nftType;
        require(nftAddress != address(0), "Market item has to exist");

        require(idToMarketItem[marketItemId].seller == msg.sender, "You are not the seller");

        if (nftType == uint8(NftType.ERC721)) {
            IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        } else if (nftType == uint8(NftType.ERC1155)) {
            IERC1155(nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                idToMarketItem[marketItemId].amount,
                ""
            );
        } else if (nftType == uint8(NftType.ThorNodeNFT)) {
            INodeRewardManagementNFT(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        }

        idToMarketItem[marketItemId].owner = payable(msg.sender);
        idToMarketItem[marketItemId].canceled = true;
        _itemsCanceled.increment();

        emit MarketItemCanceled(nftType, marketItemId, collectionId, tokenId, nftAddress, msg.sender);
    }

    function _splitPaymentWithRoyalties(
        address nftAddress,
        uint256 price,
        uint8 paymentMethod,
        address payable seller
    ) internal {
        uint256 payoutToSeller = price;
        bool hasRoyalty = royaltyManagerMainnet.hasRoyalty(nftAddress);
        if (hasRoyalty) {
            (address payable[] memory recipients, uint256[] memory amounts) = royaltyManagerMainnet.getRoyalty(
                nftAddress,
                price
            );

            //transfer royalties
            for (uint256 i = 0; i < recipients.length; i++) {
                payoutToSeller = payoutToSeller - amounts[i];
                if (paymentMethod == uint8(PaymentMethod.AVAX)) {
                    Address.sendValue(recipients[i], amounts[i]);
                } else if (paymentMethod == uint8(PaymentMethod.ERC20)) {
                    thorToken.transferFrom(msg.sender, recipients[i], amounts[i]);
                }
            }
        }
        //transfer remaining sales revenue to seller
        // seller.transfer(msg.value);
        if (paymentMethod == uint8(PaymentMethod.AVAX)) {
            Address.sendValue(seller, payoutToSeller);
        } else if (paymentMethod == uint8(PaymentMethod.ERC20)) {
            thorToken.transferFrom(msg.sender, seller, payoutToSeller);
        }
    }

    /**
     * @dev Get Latest Market Item by the token id
     */
    function getLatestMarketItemByTokenId(uint256 collectionId, uint256 tokenId)
        public
        view
        returns (MarketItem memory, bool)
    {
        uint256 itemsCount = _marketItemIds.current();

        for (uint256 i = itemsCount; i >= 1; i--) {
            MarketItem memory item = idToMarketItem[i];
            if (item.collectionId != collectionId || item.tokenId != tokenId) continue;
            return (item, true);
        }

        // What is the best practice for returning a "null" value in solidity?
        // Reverting does't seem to be the best approach as it would throw an error on frontend
        MarketItem memory emptyMarketItem;
        return (emptyMarketItem, false);
    }

    /**
     * @dev Creates a market sale by transfering msg.sender money to the seller and NFT token from the
     * marketplace to the msg.sender. It also sends the listingFee to the marketplace owner.
     */
    function createMarketSale(uint256 marketItemId, uint256 saleAmountOfErc1155) public payable nonReentrant {
        require(marketItemId > 0 && marketItemId <= _marketItemIds.current(), "marketItem not exist");
        uint8 nftType = idToMarketItem[marketItemId].nftType;
        address nftAddress = idToMarketItem[marketItemId].nftAddress;
        uint8 paymentMethod = idToMarketItem[marketItemId].paymentMethod;
        uint256 price = idToMarketItem[marketItemId].price;
        uint256 collectionId = idToMarketItem[marketItemId].collectionId;
        uint256 tokenId = idToMarketItem[marketItemId].tokenId;
        bool sold = idToMarketItem[marketItemId].sold;
        uint256 listAmount = idToMarketItem[marketItemId].amount;
        address payable creator = idToMarketItem[marketItemId].creator;
        address payable seller = idToMarketItem[marketItemId].seller;

        if (nftType == uint8(NftType.ERC1155)) {
            price = saleAmountOfErc1155.mul(price);
        }

        require(nftAddress != address(0), "Market item has to exist");
        require(sold != true, "This Sale has already finished");
        require(msg.sender != seller, "Seller cannot buy it");
        if (paymentMethod == uint8(PaymentMethod.AVAX)) {
            require(msg.value == price, "Please submit the asking price in order to complete the purchase");
            if (nftType == uint8(NftType.ERC1155)) {
                require(saleAmountOfErc1155 <= listAmount, "Sale amount must be less than listed amount in ERC1155");
            }
        }

        _splitPaymentWithRoyalties(nftAddress, price, paymentMethod, seller);

        idToMarketItem[marketItemId].owner = payable(msg.sender);
        idToMarketItem[marketItemId].sold = true;
        _itemsSold.increment();
        if (nftType == uint8(NftType.ERC1155)) {
            if (listAmount - saleAmountOfErc1155 > 0) {
                // make new idToMarketItem with remain amount of seller
                _marketItemIds.increment();
                uint256 newMarketItemId = _marketItemIds.current();

                idToMarketItem[newMarketItemId] = MarketItem(
                    nftType,
                    paymentMethod,
                    newMarketItemId,
                    collectionId,
                    tokenId,
                    listAmount - saleAmountOfErc1155,
                    price,
                    nftAddress,
                    creator,
                    seller,
                    payable(address(0)),
                    false,
                    false
                );
                idToMarketItem[marketItemId].amount = saleAmountOfErc1155;
            }
            IERC1155(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId, saleAmountOfErc1155, "");

            if (paymentMethod == uint8(PaymentMethod.AVAX)) {
                payable(owner()).transfer(saleAmountOfErc1155.mul(listingFee));
            } else if (paymentMethod == uint8(PaymentMethod.ERC20)) {
                thorToken.transfer(owner(), saleAmountOfErc1155.mul(listingFee));
            }
        } else if (nftType == uint8(NftType.ERC721)) {
            IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
            if (paymentMethod == uint8(PaymentMethod.AVAX)) {
                payable(owner()).transfer(listingFee);
            } else if (paymentMethod == uint8(PaymentMethod.ERC20)) {
                thorToken.transfer(owner(), listingFee);
            }
        } else if (nftType == uint8(NftType.ThorNodeNFT)) {
            INodeRewardManagementNFT(nftAddress).transferFrom(address(this), msg.sender, tokenId);
            if (paymentMethod == uint8(PaymentMethod.AVAX)) {
                payable(owner()).transfer(listingFee);
            } else if (paymentMethod == uint8(PaymentMethod.ERC20)) {
                thorToken.transfer(owner(), listingFee);
            }
        }

        emit MarketItemSold(marketItemId, msg.sender);
    }

    /**
     * @dev Fetch non sold and non canceled market items
     */
    function fetchMarketItems() public view returns (MarketItem[] memory, bool) {
        uint256 itemCount = _marketItemIds.current();
        uint256 unsoldItemCount = _marketItemIds.current() - _itemsSold.current() - _itemsCanceled.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        if (unsoldItemCount > 0) {
            for (uint256 i = 0; i < itemCount; i++) {
                if (idToMarketItem[i + 1].owner == address(0)) {
                    uint256 currentId = idToMarketItem[i + 1].marketItemId;
                    MarketItem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return (items, true);
        }
        return (items, false);
    }

    /**
     * @dev Fetch non list to marketplace
     */
    function fetchMyNFTs() public view returns (MarketItem[] memory, bool) {
        uint256 totalItemCount = _marketItemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        if (itemCount > 0) {
            for (uint256 i = 0; i < totalItemCount; i++) {
                if (idToMarketItem[i + 1].owner == msg.sender) {
                    uint256 currentId = idToMarketItem[i + 1].marketItemId;
                    MarketItem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return (items, true);
        }
        return (items, false);
    }

    /**
     * @dev Fetch market items created by msg.sender
     */
    function fetchItemsCreated() public view returns (MarketItem[] memory, bool) {
        uint256 totalItemCount = _marketItemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        if (itemCount > 0) {
            for (uint256 i = 0; i < totalItemCount; i++) {
                if (idToMarketItem[i + 1].seller == msg.sender) {
                    uint256 currentId = idToMarketItem[i + 1].marketItemId;
                    MarketItem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return (items, true);
        }
        return (items, false);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
