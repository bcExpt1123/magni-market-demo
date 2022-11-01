// SPDX-License-Identifier: MIT
/// @author: magni

pragma solidity ^0.8.9;
import "./CollectionEnumerable.sol";

contract CollectionFactory is CollectionEnumerable {
    uint8 private _paymentMethod;

    uint8 private _status;
    bool private _isExternalCollection;

    struct Royalty {
        address _address;
        uint8 _fee;
    }
    Royalty private _royalty;
}
