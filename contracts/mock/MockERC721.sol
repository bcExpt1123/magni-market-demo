// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MockERC721 is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address owner, string memory _tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(owner, newTokenId);
        _creators[newTokenId] = msg.sender;
        // _setTokenURI(newTokenId, _tokenURI);
        _tokenURIs[newTokenId] = _tokenURI;

        return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function getTokensOwnedByMe() public view returns (uint256[] memory items, uint256[] memory balances) {
        uint256 numberOfTokensOwned = balanceOf(msg.sender);

        items = new uint256[](numberOfTokensOwned);
        balances = new uint256[](numberOfTokensOwned);

        uint256 _counter = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (ownerOf(i + 1) != msg.sender) continue;
            items[_counter] = i + 1;
            balances[_counter] = 1;
            _counter++;
        }

        return (items, balances);
    }

    function getTokenCreatorById(uint256 tokenId) public view returns (address) {
        return _creators[tokenId];
    }

    function getTokensCreatedByMe() public view returns (uint256[] memory items, uint256[] memory balances) {
        uint256 _counter = 0;

        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (_creators[i + 1] != msg.sender) continue;
            _counter++;
        }

        items = new uint256[](_counter);
        balances = new uint256[](_counter);
        _counter = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (_creators[i + 1] != msg.sender) continue;
            items[_counter] = i + 1;
            balances[_counter] = 1;
            _counter++;
        }

        return (items, balances);
    }
}
