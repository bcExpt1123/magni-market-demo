// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MockERC721 is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    mapping(uint256 => address) private _creators;

    event TokenMinted(uint256 indexed tokenId, string tokenURI);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(address owner, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();

        _mint(owner, newItemId);
        _creators[newItemId] = msg.sender;
        _setTokenURI(newItemId, tokenURI);
        emit TokenMinted(newItemId, tokenURI);
        return newItemId;
    }
}
