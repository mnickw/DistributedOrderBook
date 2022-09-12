// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IOrderBook.sol";
import "./IDepositary.sol";

contract OrderBookLinkedList is IOrderBook {
    using SafeERC20 for IERC20;

    // TODO: Check other structures and architectures for gas consumption and performance
    //       (non-solidity solutions: trees (b trees), sparsed arrays; solidity+chainlink/web2; solidity+batches)

    struct Order {
        address owner;
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
    IDepositary internal depositaryContract;

    constructor(address exchangeTokenContractAddr, address depositaryAddr) {
        // TODO: Initialize depo contract
        exchangeTokenContract = IERC20(exchangeTokenContractAddr);
        depositaryContract = IDepositary(depositaryAddr);
    }

    // TODO: Approved order
    // TODO: Market order

    function getLowestLimitAskPrice () external view virtual override returns (uint256) {
        return lowestAsk;
    }

    function getHighestLimitBidPrice () external view virtual override returns (uint256) {
        return highestBid;
    }

    // TODO: Replace code in internal method
    function placeLimitAskOrder (
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external virtual override returns (PlaceOrderStatus) {
        require(depositaryContract.getSecurityContractValidationStatus(securityContractAddr) == SecurityContractValidationStatus.Valid,
            "Security contract address must be valid by depositary");
        require(depositaryContract.getUserValidationStatus(msg.sender) == UserValidationStatus.Valid,
            "Sender address must be valid by depositary");
        require(amount > 0, "Amount must be greater than 0");
        require(floorPrice > 0, "Floor price must be greater than 0");
        // TODO: Check overflow
        IERC20 securityContract = IERC20(securityContractAddr);
        securityContract.safeTransferFrom(msg.sender, address(this), amount);

        return _placeLimitOrder(msg.sender, securityContractAddr, amount, floorPrice, false);
    }

    // TODO: Replace code to internal method
    function placeLimitBidOrder (
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) external virtual override returns (PlaceOrderStatus) {
        require(depositaryContract.getSecurityContractValidationStatus(securityContractAddr) == SecurityContractValidationStatus.Valid,
            "Security contract address must be valid by depositary");
        require(depositaryContract.getUserValidationStatus(msg.sender) == UserValidationStatus.Valid,
            "Sender address must be valid by depositary");
        require(amount > 0, "Amount must be greater than 0");
        require(ceilingPrice > 0, "Ceiling price must be greater than 0");
        // TODO: Check overflow
        exchangeTokenContract.safeTransferFrom(msg.sender, address(this), ceilingPrice * amount);

        return _placeLimitOrder(msg.sender, securityContractAddr, amount, ceilingPrice, true);
    }

    function cancelLimitOrder (
        address securityContractAddr,
        uint256 orderPrice,
        uint32 amount,
        bool cancelIfActualAmountIsLess
    ) external virtual override returns (bool) {
        return _cancelOrder(securityContractAddr, msg.sender, orderPrice, amount, cancelIfActualAmountIsLess);
    }

    // TODO: Maybe separate bids and asks funcs (not mapping) for gas opt
    function _placeLimitOrder (
        address orderOwner,
        address securityContractAddr,
        uint32 amount,
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual returns (PlaceOrderStatus) {
        (uint32 restAmount, uint256 spentMoney) = _closePositionsForOrder(orderOwner, securityContractAddr, amount, orderPrice, isBidOrder);
        
        if (isBidOrder) {
            uint256 restMoney = orderPrice*amount - spentMoney - orderPrice*restAmount;
            if (restMoney != 0) exchangeTokenContract.safeTransfer(orderOwner, restMoney);
        }

        if (restAmount == 0) return PlaceOrderStatus.Filled;
        PlaceOrderStatus result = restAmount == amount ? PlaceOrderStatus.PartiallyFilledAndPlaced : PlaceOrderStatus.PartiallyFilledAndPlaced;

        _drawToOrderBook(orderOwner, securityContractAddr, amount, orderPrice, isBidOrder);

        return result;
    }

    // TODO: Don't close position if asker and bidder is same owner
    function _closePositionsForOrder (
        address orderOwner,
        address securityContractAddr,
        uint32 amount,
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual returns (uint32, uint256) { // returns rest amount to draw to order book and spent money for further calculating rest for bidder orders
        uint256 spentMoney = 0;
        // TODO: (edgePriceEvent) uint256 oldEdgePrice = isBidOrder ? lowestAsk : highestBid;
        while (amount != 0 && _orderIntersectionExists(orderPrice, isBidOrder)) {
            uint256 currentPrice = isBidOrder ? lowestAsk : highestBid;
            Price storage currentPriceNode = priceNodes[securityContractAddr][currentPrice];
            while (amount != 0 && currentPriceNode.headOrderId != 0) {
                uint128 currentOrderId = currentPriceNode.headOrderId;
                Order storage currentOrder = orders[currentOrderId];
                (address bidder, address asker) = isBidOrder ? (orderOwner, currentOrder.owner) : (currentOrder.owner, orderOwner);
                if (amount < currentOrder.amount) {
                    _executeTrade(securityContractAddr, bidder, asker, amount, currentPrice);
                    spentMoney += currentPrice*amount;
                    currentOrder.amount -= amount;
                    // TODO: (edgePriceEvent) _emitEdgePriceChangeEventIfNeeded(isBidOrder, oldEdgePrice);
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
        // TODO: (edgePriceEvent) _emitEdgePriceChangeEventIfNeeded(isBidOrder, oldEdgePrice);
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
        address asker,
        uint32 amount,
        uint256 price
    ) internal virtual {
        exchangeTokenContract.safeTransfer(asker, price*amount);
        IERC20 securityContract = IERC20(securityContractAddr);
        securityContract.safeTransfer(bidder, amount);
        emit ExecuteTrade(securityContractAddr, bidder, asker, amount, price);
    }

    // TODO: (edgePriceEvent) 
    // function _emitEdgePriceChangeEventIfNeeded (
    //     bool isBidOrder,
    //     uint256 oldEdgePrice) internal virtual {
    //     if (isBidOrder && lowestAsk != oldEdgePrice)
    //         emit LowestLimitAskPriceChanged(lowestAsk, oldEdgePrice);
    //     else if (!isBidOrder && highestBid != oldEdgePrice)
    //         emit HighestLimitBidPriceChanged(highestBid, oldEdgePrice);
    // }

    function _drawToOrderBook (
        address orderOwner,
        address securityContractAddr,
        uint32 amount,
        uint256 orderPrice,
        bool isBidOrder
    ) internal virtual {
        Order storage order = orders[++orderIdCounter];
        order.amount = amount;
        order.owner = orderOwner;
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
                if (isBidOrder) {
                    // TODO: (edgePriceEvent) emit HighestLimitBidPriceChanged(orderPrice, highestBid);
                    highestBid = orderPrice;
                }
                else {
                    // TODO: (edgePriceEvent) emit LowestLimitAskPriceChanged(orderPrice, lowestAsk);
                    lowestAsk = orderPrice;
                }
            }
            else priceNodes[securityContractAddr][priceToPutAfter].nextPrice = orderPrice;
        }
        
        emit DrawToOrderBook(securityContractAddr, orderOwner, isBidOrder, amount, orderPrice);
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

    function _cancelOrder (
        address securityContractAddr,
        address orderOwner,
        uint256 orderPrice,
        uint32 amount,
        bool cancelIfActualAmountIsLess
    ) internal virtual returns (bool) {
        uint32 restAmount = amount;
        Price storage currentPrice = priceNodes[securityContractAddr][orderPrice];
        uint128 currentOrderId = currentPrice.headOrderId;
        uint128 prevOrderId = 0;
        Order storage currentOrder;
        while (currentOrderId != 0 && restAmount != 0) {
            currentOrder = orders[currentOrderId];
            if (currentOrder.owner != orderOwner) {
                prevOrderId = currentOrderId;
                currentOrderId = currentOrder.nextOrderId; 
                continue;
            }
            if (restAmount < currentOrder.amount) {
                currentOrder.amount -= restAmount;
                restAmount = 0;
                break;
            }
            restAmount -= currentOrder.amount;
            if (currentPrice.headOrderId == currentOrderId) {
                currentPrice.headOrderId = currentOrder.nextOrderId;
                delete orders[currentOrderId];
                currentOrderId = currentPrice.headOrderId;
                continue;
            }
            if (prevOrderId != 0) {
                Order storage prevOrder = orders[prevOrderId];
                prevOrder.nextOrderId = currentOrder.nextOrderId;
                delete orders[currentOrderId];
                currentOrderId = prevOrder.nextOrderId;
                continue;
            }
        }
        if (currentPrice.headOrderId == 0) {
            if (orderPrice == lowestAsk) lowestAsk = currentPrice.nextPrice;
            else if (orderPrice == highestBid) highestBid = currentPrice.nextPrice;
            delete priceNodes[securityContractAddr][orderPrice];
        }
        require(restAmount != amount, "No order to cancel");
        require(cancelIfActualAmountIsLess || restAmount == 0, "Actual amount is less");
        return true;
    }
}