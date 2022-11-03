// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyManager is IERC165 {
    /**
     * Checks if a royalty exists for a given collection (address).
     *
     * @param collectionAddress - The address of the collection
     *
     */
    function hasRoyalty(address collectionAddress) external returns (bool);

    /**
     * Get the royalty for a given collection (address) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param collectionAddress - The address of the collection
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address collectionAddress, uint256 value)
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * Set the royalty for a given collection (address) and value amount.
     *
     * @param collectionAddress - The address of the collection
     * @param recipients        - The addresses of the recipient
     * @param feePercents       - The fees for recipient to receive
     *
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] memory recipients,
        uint256[] memory feePercents
    ) external;
}
