// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @author: magni
/// @sample: https://support.opensea.io/hc/en-us/articles/1500009575482-How-do-creator-earnings-work-on-OpenSea-

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IRoyaltyManager.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyManager is ERC165, IRoyaltyManager {
    struct Royalty {
        address payable[] recipients;
        uint256[] feePercents;
    }

    mapping(address => Royalty) private collectionToRoyalty;

    /**
     * @dev See {IRoyaltyManager-hasRoyalty}
     */
    function hasRoyalty(address collectionAddress)
        public
        view
        override
        returns (bool)
    {
        Royalty memory royalty = collectionToRoyalty[collectionAddress];
        return royalty.recipients.length > 0;
    }

    /**
     * @dev See {IRoyaltyManager-getRoyalty}
     */
    function getRoyalty(address collectionAddress, uint256 value)
        public
        view
        override
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        // return (_recipients, _amounts);
        Royalty memory royalty = collectionToRoyalty[collectionAddress];
        require(
            hasRoyalty(collectionAddress),
            "This collection has not any royalty"
        );
        uint256[] memory royaltyValues = new uint256[](
            royalty.recipients.length
        );

        for (uint256 i = 0; i < royalty.recipients.length; i++) {
            royaltyValues[i] = (value * royalty.feePercents[i]) / 100;
        }
        return (royalty.recipients, royaltyValues);
    }

    /**
     * @dev See {IRoyaltyManager-setRoyalty}
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] memory recipients,
        uint256[] memory feePercents
    ) public override {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(feePercents[i] <= 15, "Fees can not be larger than 15%");
            for (uint256 j = i + 1; j < recipients.length; j++) {
                require(
                    recipients[i] != recipients[j],
                    "Recipients can not be duplicated"
                );
            }
        }
        collectionToRoyalty[collectionAddress] = Royalty(
            recipients,
            feePercents
        );
    }
}
