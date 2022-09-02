// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract OrderBookLinkedList is IOrderBook {
    using SafeERC20 for IERC20;

    // TODO: Check other structures and architectures for gas consumption and performance
    //       (non-solidity solutions: trees (b trees), sparsed arrays; solidity+chainlink/web2; solidity+batches)

    struct Order {
        address payable owner;
        uint32 amount;
        uint128 nextOrderId;
    }

    struct Price {
        uint256 nextPrice;
        uint128 headOrderId;
        uint128 tailOrderId;
    }

    // TODO: Need 2 check gas consumption of nested map vs combined key (via abi.encode?)
    mapping(address => mapping(uint256 => Price)) internal priceNodes; // securityContract => (price => Price))
    mapping(uint128 => Order) internal orders;
    uint256 internal lowestAsk;
    uint256 internal highestBid;
    uint128 internal orderIdCounter;

    constructor() {
        // TODO: Initialize depo contract
    }

    // TODO: Cancel order
    // TODO: Approved order
    // TODO: Market order

    function placeLimitAskOrder (
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external virtual override returns (PlaceOrderStatus) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        SafeERC20 securityContract = SafeERC20(securityContractAddr);
        securityContract.safeTransferFrom(from, address(this), amount);

        return _placeOrder(payable(msg.sender), securityContractAddr, amount, floorPrice, false);
    }

    function placeLimitBidOrder (
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) external payable virtual override returns (PlaceOrderStatus) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        require(msg.value == (ceilingPrice * amount), "Incorrect fund sent.");

        return _placeOrder(payable(msg.sender), securityContractAddr, amount, ceilingPrice, true);
    }

    function _placeOrder (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 lastPrice,
        bool isBidOrder
    ) internal virtual returns (PlaceOrderStatus) {
        uint32 restAmount = _closePositionsForAskOrder(from, securityContractAddr, amount, lastPrice, isBidOrder);
        if (restAmount == 0) return PlaceOrderStatus.Filled;
        PlaceOrderStatus result = restAmount == amount ? PlaceOrderStatus.PartiallyFilledAndPlaced : PlaceOrderStatus.PartiallyFilledAndPlaced;

        _drawToOrderBook(from, securityContractAddr, amount, lastPrice, isBidOrder);

        return result;
    }

    function _closePositionsForOrder (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 lastPrice,
        bool isBidOrder
    ) internal virtual returns (uint32) { // returns rest amount to draw in order book
        while (amount != 0 && _orderIntersectionExists(lastPrice, isBidOrder)) {
            uint256 currentPrice = isBidOrder ? lowestAsk : highestBid;
            Price storage currentPriceNode = priceNodes[securityContractAddr][currentPrice];
            while (currentPriceNode.headOrderId != 0) {
                uint128 currentOrderId = currentPriceNode.headOrderId;
                Order storage currentOrder = orders[currentOrderId];
                (address bidder, address payable asker) = isBidOrder ? (from, currentOrder.owner) : (currentOrder.owner, from);
                if (amount < currentOrder.amount) {
                    _executeTrade(securityContractAddr, bidder, asker, amount, currentPrice);
                    currentOrder.amount -= amount;
                    return 0;
                }
                _executeTrade(securityContractAddr, bidder, asker, currentOrder.amount, currentPrice);
                amount -= currentOrder.amount;
                currentPriceNode.headOrderId = currentOrder.nextOrderId;
                delete orders[currentOrderId];
            }
            if (isBidOrder) lowestAsk = currentPriceNode.nextPrice;
            else highestBid = currentPriceNode.nextPrice;
            delete priceNodes[securityContractAddr][currentPrice];
        }
        return amount;
    }

    function _orderIntersectionExists (
        uint256 price,
        bool isBidOrder
    ) internal virtual returns (bool) {
        return ((isBidOrder && (price >= lowestAsk && lowestAsk != 0)) || (!isBidOrder && (price <= highestBid)));
    }

    function _executeTrade (
        address securityContractAddr,
        address bidder,
        address payable asker,
        uint32 amount,
        uint256 price
    ) internal virtual {
        (bool sent, bytes memory data) = asker.call{value: price*amount}("");
        require(sent, "Failed to send Ether");
        SafeERC20 securityContract = SafeERC20(securityContractAddr);
        securityContract.safeTransfer(bidder, amount);
        ExecuteTrade (securityContractAddr, bidder, asker, amount, price);
    }

    function _drawToOrderBook (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 price,
        bool isBidOrder
    ) internal virtual {
        Order storage order = orders[++orderIdCounter];
        order.amount = amount;
        order.owner = from;
        Price storage priceNode = priceNodes[securityContractAddr][price];
        if (priceNode.headOrderId == 0) priceNode.headOrderId = orderIdCounter;
        else orders[priceNode.tailOrderId].nextOrderId = orderIdCounter;
        priceNode.tailOrderId = orderIdCounter;
        if (isBidOrder) {
            priceNode.nextPrice = highestBid;
            highestBid = price;
        }
        else {
            priceNode.nextPrice = lowestAsk;
            lowestAsk = price;
        }
        DrawToOrderBook(securityContractAddr, from, isBidOrder, amount, price);
    } 
}