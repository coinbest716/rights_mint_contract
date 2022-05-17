// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMarketPlace {
    function createMarketItem(
        address nftOwner,
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external;
}
