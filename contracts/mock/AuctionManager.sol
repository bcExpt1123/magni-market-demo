// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

// import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Auction.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AuctionManager {
    enum NftType {
        ERC721,
        ERC1155
    }

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _auctionItemIds; // auction Id counter
    mapping(uint256 => Auction) public auctions; // auctions

    ERC20 thorToken;
    IRoyaltyManager royaltyManagerMainnet;

    constructor(address thorV2Address, address royaltyManagerAddress) {
        thorToken = ERC20(thorV2Address);
        royaltyManagerMainnet = IRoyaltyManager(royaltyManagerAddress);
    }

    // create an auction
    function createAuction(
        uint256 endTime,
        uint256 minIncrement,
        uint256 directBuyPrice,
        uint256 startPrice,
        uint256 amount,
        uint8 nftType,
        address nftContract,
        uint256 tokenId,
        uint8 paymentMethod
    ) external returns (bool) {
        if (nftType == uint8(NftType.ERC721)) {
            require(
                IERC721(nftContract).ownerOf(tokenId) == msg.sender,
                "You are not owner of this token"
            );
        } else if (nftType == uint8(NftType.ERC1155)) {
            require(
                amount <= IERC1155(nftContract).balanceOf(msg.sender, tokenId),
                "Listing fee must be equal to listing fee of ERC1155"
            );
        }
        require(directBuyPrice > 0, "direct buy price must be greater than 0");
        require(
            startPrice < directBuyPrice,
            "start price is smaller than direct buy price"
        );
        require(endTime > 5 minutes, "end time must be greater than 5 minutes");

        uint256 auctionId = _auctionItemIds.current(); // get the current value of the counter
        _auctionItemIds.increment();
        Auction auction = new Auction(
            msg.sender,
            endTime,
            minIncrement,
            directBuyPrice,
            startPrice,
            amount,
            nftType,
            nftContract,
            tokenId,
            paymentMethod,
            thorToken,
            royaltyManagerMainnet
        ); // create the auction

        if (nftType == uint8(NftType.ERC721)) {
            // transfer the token to the auction
            IERC721(nftContract).transferFrom(
                msg.sender,
                address(auction),
                tokenId
            );
        } else if (nftType == uint8(NftType.ERC1155)) {
            // transfer the token to the auction
            IERC1155(nftContract).safeTransferFrom(
                msg.sender,
                address(auction),
                tokenId,
                amount,
                ""
            );
        }

        auctions[auctionId] = auction; // add the auction to the map
        return true;
    }

    // Return a list of all auctions
    function getAuctions() external view returns (address[] memory _auctions) {
        uint256 auctionCount = _auctionItemIds.current();
        _auctions = new address[](auctionCount); // create an array of size equal to the current value of the counter
        for (uint256 i = 0; i < auctionCount; i++) {
            _auctions[i] = address(auctions[i]); // add the address of the auction to the array
        }
        return _auctions;
    }

    // Return the information of each auction address
    function getAuctionInfo(address[] calldata _auctionsList)
        external
        view
        returns (
            uint256[] memory directBuyPrice,
            address[] memory owner,
            uint256[] memory highestBid,
            uint256[] memory tokenIds,
            uint256[] memory endTime,
            uint256[] memory startPrice,
            uint256[] memory amount,
            uint256[] memory auctionState
        )
    {
        directBuyPrice = new uint256[](_auctionsList.length); // create an array of size equal to the length of the passed array
        owner = new address[](_auctionsList.length); // create an array of size equal to the length of the passed array
        highestBid = new uint256[](_auctionsList.length);
        tokenIds = new uint256[](_auctionsList.length);
        endTime = new uint256[](_auctionsList.length);
        startPrice = new uint256[](_auctionsList.length);
        amount = new uint256[](_auctionsList.length);
        auctionState = new uint256[](_auctionsList.length);

        for (uint256 i = 0; i < _auctionsList.length; i++) {
            directBuyPrice[i] = Auction(auctions[i]).directBuyPrice();
            owner[i] = Auction(auctions[i]).creator();
            highestBid[i] = Auction(auctions[i]).maxBid();
            tokenIds[i] = Auction(auctions[i]).tokenId();
            endTime[i] = Auction(auctions[i]).endTime();
            startPrice[i] = Auction(auctions[i]).startPrice();
            amount[i] = Auction(auctions[i]).amount();
            auctionState[i] = uint256(Auction(auctions[i]).getAuctionState());
        }
        return (
            directBuyPrice,
            owner,
            highestBid,
            tokenIds,
            endTime,
            startPrice,
            amount,
            auctionState
        );
    }
}
