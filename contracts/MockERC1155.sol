// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MockERC1155 is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    string public name = "";
    string public symbol = "";

    event TokenMinted(uint256 indexed tokenId, string tokenURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(string(abi.encodePacked(_uri, "{id}"))) {
        name = _name;
        symbol = _symbol;
    }

    function myItems()
        external
        view
        returns (uint256[] memory items, uint256[] memory balances)
    {
        // Returns an array of items that the user owns
        uint256 _counter = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (balanceOf(msg.sender, i) > 0) {
                // if the user owns the item
                _counter++;
            }
        }

        items = new uint256[](_counter);
        balances = new uint256[](_counter);
        _counter = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (balanceOf(msg.sender, i) > 0) {
                // if the user owns the item
                items[_counter] = i;
                balances[_counter] = balanceOf(msg.sender, i);
                _counter++;
            }
        }

        return (items, balances);
    }

    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function mint(address ownerAddress, string memory tokenURI, uint256 value) public {
        require(ownerAddress != address(0), "ERC1155: mint to the zero address");
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();

        _mint(ownerAddress, newTokenId, value, "");
        emit TokenMinted(newTokenId, uri(newTokenId));
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
