// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IOrderBook.sol";

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
    mapping(uint128 => Order) internal orders; // orderId => Order
    uint256 internal lowestAsk;
    uint256 internal highestBid;
    uint128 internal orderIdCounter;

    IERC20 internal exchangeTokenContract;

    constructor(address exchangeTokenContractAddr) {
        // TODO: Initialize depo contract
        exchangeTokenContract = IERC20(exchangeTokenContractAddr);
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

        // TODO: Check overflow
        IERC20 securityContract = IERC20(securityContractAddr);
        securityContract.safeTransferFrom(msg.sender, address(this), amount);

        return _placeOrder(payable(msg.sender), securityContractAddr, amount, floorPrice, false);
    }

    function placeLimitBidOrder (
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) external payable virtual override returns (PlaceOrderStatus) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        // TODO: Check overflow
        require(msg.value == (ceilingPrice * amount), "Incorrect fund sent.");

        return _placeOrder(payable(msg.sender), securityContractAddr, amount, ceilingPrice, true);
    }

    // TODO: Maybe separate bids and asks funcs (not mapping) for gas opt
    function _placeOrder (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual returns (PlaceOrderStatus) {
        (uint32 restAmount, uint256 spentMoney) = _closePositionsForOrder(from, securityContractAddr, amount, orderPrice, isBidOrder);
        
        if (isBidOrder) {
            uint256 restMoney = orderPrice*amount - spentMoney - orderPrice*restAmount;
            if (restMoney != 0) exchangeTokenContract.safeTransfer(from, restMoney);
        }

        if (restAmount == 0) return PlaceOrderStatus.Filled;
        PlaceOrderStatus result = restAmount == amount ? PlaceOrderStatus.PartiallyFilledAndPlaced : PlaceOrderStatus.PartiallyFilledAndPlaced;

        _drawToOrderBook(from, securityContractAddr, amount, orderPrice, isBidOrder);

        return result;
    }

    function _closePositionsForOrder (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual returns (uint32, uint256) { // returns rest amount to draw to order book and spent money for further calculating rest for bidder orders
        uint256 spentMoney = 0;
        while (amount != 0 && _orderIntersectionExists(orderPrice, isBidOrder)) {
            uint256 currentPrice = isBidOrder ? lowestAsk : highestBid;
            Price storage currentPriceNode = priceNodes[securityContractAddr][currentPrice];
            while (amount != 0 && currentPriceNode.headOrderId != 0) {
                uint128 currentOrderId = currentPriceNode.headOrderId;
                Order storage currentOrder = orders[currentOrderId];
                (address bidder, address payable asker) = isBidOrder ? (from, currentOrder.owner) : (currentOrder.owner, from);
                if (amount < currentOrder.amount) {
                    _executeTrade(securityContractAddr, bidder, asker, amount, currentPrice);
                    spentMoney += currentPrice*amount;
                    currentOrder.amount -= amount;
                    return (0, spentMoney);
                }
                _executeTrade(securityContractAddr, bidder, asker, currentOrder.amount, currentPrice);
                spentMoney += currentPrice*currentOrder.amount;
                amount -= currentOrder.amount;
                currentPriceNode.headOrderId = currentOrder.nextOrderId;
                delete orders[currentOrderId];
            }
            if (currentPriceNode.headOrderId == 0) {
                if (isBidOrder) lowestAsk = currentPriceNode.nextPrice;
                else highestBid = currentPriceNode.nextPrice;
                delete priceNodes[securityContractAddr][currentPrice];
            }
        }
        return (amount, spentMoney);
    }

    function _orderIntersectionExists (
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual returns (bool) {
        return (isBidOrder && (orderPrice >= lowestAsk && lowestAsk != 0))
            || (!isBidOrder && (orderPrice <= highestBid));
    }

    function _executeTrade (
        address securityContractAddr,
        address bidder,
        address payable asker,
        uint32 amount,
        uint256 price
    ) internal virtual {
        exchangeTokenContract.safeTransfer(asker, price*amount);
        IERC20 securityContract = IERC20(securityContractAddr);
        securityContract.safeTransfer(bidder, amount);
        emit ExecuteTrade(securityContractAddr, bidder, asker, amount, price);
    }

    function _drawToOrderBook (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual {
        Order storage order = orders[++orderIdCounter];
        order.amount = amount;
        order.owner = from;
        Price storage priceNode = priceNodes[securityContractAddr][orderPrice];

        if (priceNode.headOrderId != 0) {
            orders[priceNode.tailOrderId].nextOrderId = orderIdCounter;
            priceNode.tailOrderId = orderIdCounter;
        }
        else {
            priceNode.headOrderId = orderIdCounter;
            priceNode.tailOrderId = orderIdCounter;

            uint256 priceToPutAfter = 0;
            uint256 priceToPutBefore = isBidOrder ? highestBid : lowestAsk;
            while (!_priceToPutBeforeFits(orderPrice, priceToPutBefore, isBidOrder)) {
                priceToPutAfter = priceToPutBefore;
                priceToPutBefore = priceNodes[securityContractAddr][priceToPutBefore].nextPrice;
            }
            if (priceToPutBefore != 0) priceNode.nextPrice = priceToPutBefore;
            if (priceToPutAfter == 0) {
                if (isBidOrder) highestBid = orderPrice;
                else lowestAsk = orderPrice;
            }
            else priceNodes[securityContractAddr][priceToPutAfter].nextPrice = orderPrice;
        }
        
        emit DrawToOrderBook(securityContractAddr, from, isBidOrder, amount, orderPrice);
    }

    function _priceToPutBeforeFits (
        uint256 orderPrice,
        uint256 priceToPutBefore,
        bool isBidOrder
    ) internal virtual returns (bool) {
        return priceToPutBefore == 0
            || (isBidOrder && priceToPutBefore < orderPrice)
            || (!isBidOrder && orderPrice < priceToPutBefore);
    }
}