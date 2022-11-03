// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

// import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./CollectionEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IRoyaltyManager.sol";

contract Auction is CollectionEnumerable {
    // using SafeMath for uint256;
    address public creator; // The address of the auction creator
    uint8 public nftType; // The type of the NFT (721, or 1155)
    uint256 public amount; // The amount for the auction in ERC1155 tokens
    address public nftContract; // The address of the NFT contract
    uint256 public tokenId; // The id of the token

    uint256 public startPrice; // The starting price for the auction
    uint256 public endTime; // Timestamp of the end of the auction (in seconds)
    uint256 public minIncrement; // The minimum increment for the bid
    uint256 public directBuyPrice; // The price for a direct buy

    uint256 public maxBid; // The maximum bid
    address public maxBidder; // The address of the maximum bidder
    Bid[] public bids; // The bids made by the bidders

    bool isCancelled; // if the auction is AuctionCancelled()
    bool isDirectBuy; // True if the auction ended due to direct buy
    uint8 public paymentMethod;
    ERC20 thorToken;
    IRoyaltyManager royaltyManagerMainnet;

    enum AuctionState {
        OPEN,
        CANCELLED,
        ENDED,
        DIRECT_BUY
    }

    struct Bid {
        // A bid on an auction
        address sender;
        uint256 bid;
    }

    // Auction constructor
    constructor(
        address _creator,
        uint256 _endTime,
        uint256 _minIncrement,
        uint256 _directBuyPrice,
        uint256 _startPrice,
        uint256 _amount,
        uint8 _nftType,
        address _nftContract,
        uint256 _tokenId,
        uint8 _paymentMethod,
        ERC20 _thorToken,
        IRoyaltyManager _royaltyManagerMainnet
    ) {
        creator = _creator; // The address of the auction creator
        endTime = block.timestamp + _endTime; // The timestamp which marks the end of the auction (now + 30 days = 30 days from now)
        minIncrement = _minIncrement; // The minimum increment for the bid
        directBuyPrice = _directBuyPrice; // the price for a direct buy
        startPrice = _startPrice; // The Starting price for the auction
        nftType = _nftType; // The type of the nft
        amount = _amount;
        nftContract = _nftContract;
        tokenId = _tokenId; // the id of the token
        maxBidder = _creator; // Setting the maxBidder to auction creator
        paymentMethod = _paymentMethod;
        thorToken = _thorToken;
        royaltyManagerMainnet = _royaltyManagerMainnet;
    }

    // Returns a list of all bids and addresses
    function allBids()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory addrs = new address[](bids.length);
        uint256[] memory bidPrice = new uint256[](bids.length);
        for (uint256 i = 0; i < bids.length; i++) {
            addrs[i] = bids[i].sender;
            bidPrice[i] = bids[i].bid;
        }
        return (addrs, bidPrice);
    }

    // Place a bid on the auction
    // erc20Amount : The amount of ERC20 token in case of ERC20 payment, 0 in case of AVAX payment
    function placeBid(uint256 erc20Amount) external payable returns (bool) {
        require(msg.sender != creator, "bidder cannot be token creator");
        require(
            getAuctionState() == uint256(AuctionState.OPEN),
            "auction state should be open"
        );
        uint256 price = erc20Amount;
        if (paymentMethod == uint8(PaymentMethod.AVAX)) {
            price = msg.value;
        }

        require(price > startPrice, "bid price is greater than start price");
        require(
            price > maxBid + minIncrement,
            "bid price is greater than maxBid + minIncrement"
        );

        address lastHighestBidder = maxBidder;
        uint256 lastHighestBid = maxBid;
        maxBid = price;
        maxBidder = msg.sender;

        if (paymentMethod == uint8(PaymentMethod.ERC20)) {
            thorToken.transferFrom(msg.sender, address(this), price);
        }

        if (price >= directBuyPrice) {
            // If the bid is higher or equal to the direct buy price
            isDirectBuy = true; // The auction has ended
        }
        bids.push(Bid(msg.sender, price));

        if (lastHighestBid != 0) {
            // if there is a bid
            // address(uint160(lastHighestBidder)).transfer(lastHighestBid);
            if (paymentMethod == uint8(PaymentMethod.ERC20)) {
                thorToken.transferFrom(
                    address(this),
                    lastHighestBidder,
                    lastHighestBid
                );
            } else if (paymentMethod == uint8(PaymentMethod.AVAX)) {
                payable(lastHighestBidder).transfer(lastHighestBid);
            }
            // refund the previous bid to the previous highest bidder
        }

        emit NewBid(msg.sender, price);
        return true;
    }

    // Withdraw the token after the auction is over
    function withdrawToken() external returns (bool) {
        require(
            getAuctionState() == uint256(AuctionState.ENDED) ||
                getAuctionState() == uint256(AuctionState.DIRECT_BUY),
            "The auction must be ended by either a direct buy or timeout"
        );
        require(
            msg.sender == maxBidder,
            "The highest bidder can only withdraw the token"
        );
        if (nftType == uint8(NftType.ERC721)) {
            IERC721(nftContract).transferFrom(
                address(this),
                maxBidder,
                tokenId
            ); // Transfer the token to the highest bidder
        } else if (nftType == uint8(NftType.ERC1155)) {
            IERC1155(nftContract).safeTransferFrom(
                address(this),
                maxBidder,
                tokenId,
                amount,
                ""
            );
        }
        emit WithdrawToken(maxBidder);
        return true;
    }

    // Withdraw the funds after the auction is over
    function withdrawFunds() external returns (bool) {
        require(
            getAuctionState() == uint256(AuctionState.ENDED) ||
                getAuctionState() == uint256(AuctionState.DIRECT_BUY),
            "The auction must be ended by either a direct buy or timeout"
        );
        require(
            msg.sender == creator,
            "The auction creator can only withdraw the funds"
        );
        if (paymentMethod == uint8(PaymentMethod.ERC20)) {
            thorToken.approve(address(this), maxBid);
            thorToken.transferFrom(address(this), msg.sender, maxBid);
        } else if (paymentMethod == uint8(PaymentMethod.AVAX)) {
            payable(msg.sender).transfer(maxBid);
        }
        emit WithdrawFunds(msg.sender, maxBid);
        return true;
    }

    // Cancel the auction
    function cancelAuction() external returns (bool) {
        require(
            msg.sender == creator,
            "Only the auction creator can cancel the auction"
        );
        require(
            getAuctionState() == uint256(AuctionState.OPEN),
            "The auction must be open"
        );
        require(
            maxBid == 0,
            "The auction must not be cancelled if there is a bid"
        );
        isCancelled = true; // The auction has been cancelled

        if (nftType == uint8(NftType.ERC721)) {
            IERC721(nftContract).transferFrom(address(this), creator, tokenId); // Transfer the NFT token to the auction creator
        } else if (nftType == uint8(NftType.ERC1155)) {
            IERC1155(nftContract).safeTransferFrom(
                address(this),
                creator,
                tokenId,
                amount,
                ""
            );
        }
        emit AuctionCancelled();
        return true;
    }

    // Get the auction state
    function getAuctionState() public view returns (uint256) {
        if (isCancelled) return uint256(AuctionState.CANCELLED);
        if (isDirectBuy) return uint256(AuctionState.DIRECT_BUY);
        if (block.timestamp >= endTime) return uint256(AuctionState.ENDED);
        return uint256(AuctionState.OPEN);
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

    event NewBid(address bidder, uint256 bid); // A new bid was placed
    event WithdrawToken(address withdrawer); // The auction winner withdrawed the token
    event WithdrawFunds(address withdrawer, uint256 amount); // The auction owner withdrawed the funds
    event AuctionCancelled(); // The auction was cancelled
}
