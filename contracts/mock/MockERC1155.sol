// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract MockERC1155 is ERC1155URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;
    mapping(uint256 => address) private _creators;

    string public name = "";
    string public symbol = "";

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(string(abi.encodePacked(_uri, "{id}"))) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return uri(tokenId);
    }

    function mint(
        address ownerAddress,
        string memory _tokenURI,
        uint256 value
    ) public returns (uint256) {
        require(ownerAddress != address(0), "ERC1155: mint to the zero address");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(ownerAddress, newTokenId, value, "");
        _creators[newTokenId] = msg.sender;
        _setURI(newTokenId, _tokenURI);
        return newTokenId;
    }

    function getTokensOwnedByMe() external view returns (uint256[] memory items, uint256[] memory balances) {
        // Returns an array of items that the user owns
        uint256 _counter = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (balanceOf(msg.sender, i + 1) > 0) {
                // if the user owns the item
                _counter++;
            }
        }

        items = new uint256[](_counter);
        balances = new uint256[](_counter);
        _counter = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (balanceOf(msg.sender, i + 1) > 0) {
                // if the user owns the item
                items[_counter] = i + 1;
                balances[_counter] = balanceOf(msg.sender, i + 1);
                _counter++;
            }
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
            balances[_counter] = balanceOf(msg.sender, i + 1);
            _counter += 1;
        }

        return (items, balances);
    }

    // // function mintBatch(
    // //     address to,
    // //     uint256[] memory ids,
    // //     uint256[] memory values,
    // //     bytes memory data
    // // ) public {
    // //     _mintBatch(to, ids, values, data);
    // // }

    // function burn(
    //     address owner,
    //     uint256 id,
    //     uint256 value
    // ) public {
    //     _burn(owner, id, value);
    // }

    // function burnBatch(
    //     address owner,
    //     uint256[] memory ids,
    //     uint256[] memory values
    // ) public {
    //     _burnBatch(owner, ids, values);
    // }
}
