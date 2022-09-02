// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOrderBook {
    enum PlaceOrderStatus { Filled, Placed, PartiallyFilledAndPlaced }

    event ExecuteTrade (address indexed securityContractAddr, address indexed bidder, address indexed asker, uint32 amount, uint256 price);
    event DrawToOrderBook (address indexed securityContractAddr, address indexed owner, bool indexed isBidOrder, uint32 amount, uint256 price);

    function placeAskOrder(
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external returns (PlaceOrderStatus);

    function placeBidOrder(
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) external payable returns (PlaceOrderStatus);
}