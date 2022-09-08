// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOrderBook {
    enum PlaceOrderStatus { Filled, Placed, PartiallyFilledAndPlaced }

    event ExecuteTrade (address indexed securityContractAddr, address indexed bidder, address indexed asker, uint32 amount, uint256 price);
    event DrawToOrderBook (address indexed securityContractAddr, address indexed owner, bool indexed isBidOrder, uint32 amount, uint256 price);

    function placeLimitAskOrder(
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external returns (PlaceOrderStatus);

    function placeLimitBidOrder(
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) external returns (PlaceOrderStatus);

    // Your app can calculate actual amount from events
    function cancelLimitOrder (
        address securityContractAddr,
        uint256 orderPrice,
        uint32 amount,
        bool cancelIfActualAmountIsLess
    ) external returns (bool); // returns true if cancellation happened
}