pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LimitOrderBookSimpleTree is ILimitOrderBook {
    using SafeERC20 for IERC20;

    // TODO: Need 2 check gas consumption nested maps vs abi.encode for key from several values
    // TODO: Check other structures and architectures for gas consumption and performance

    struct Order {
        uint32 amount;
        address nextOrderOwner;
    }

    struct Price {
        uint256 parentPrice;
        uint256 leftPrice;
        uint256 rightPrice;
        uint256 headOrderOwner;
    }

    struct PriceWithOrders {
        Price priceNode;
        mapping(address => Order) orders; // owner => Order
    }

    mapping(address => mapping(uint256 => PriceWithOrders)) internal sells; // securityContract => (price => PriceWithOrders))
    mapping(address => mapping(uint256 => PriceWithOrders)) internal buys; // securityContract => (price => PriceWithOrders))
    uint256 lowestSell internal;
    uint256 highestBuy internal;

    constructor() {
        // TODO: Initialize depo contract
    }

    // TODO: Cancel order
    // TODO: Approved orders
    // TODO: Market order

    function placeSellOrder (
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external virtual override returns (bool) {
        _placeSellOrder(payable(msg.sender), securityContractAddr, amount, floorPrice);
    }

    function placeBuyOrder (
        address securityContractAddr
        uint32 amount,
        uint256 ceilingPrice
    ) external payable virtual override returns (bool) {
        _placeBuyOrder(payable(msg.sender), securityContractAddr, amount, ceilingPrice);
    }

    function _placeSellOrder (
        address payable from,
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) internal virtual returns (bool) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        SafeERC20 securityContract = SafeERC20(securityContractAddr);
        securityContract.safeTransferFrom(from, address(this), amount);

        uint32 restAmount = amount;
        // Remove buys
        // Close positions (maybe before remove?)
        //   Send securities to asker
        //   Send money to bidder
        if (restAmount == 0) return true;
        // Add rest sells
        PriceWithOrders storage sell = sells[securityContractAddr][floorPrice];
        (bool orderExists, Order storage order) = _orderExists(sell, from);
        order.amount += restAmount;
        if (orderExists) return true;
        if (_priceNodeExists(sell)) {
            order.nextOrderOwner = sell.priceNode.headOrderOwner;
            sell.priceNode.headOrderOwner = owner;
            return true;
        }
        sell.priceNode.headOrderOwner = owner;
        Price storage currentPriceNode = sells[securityContractAddr][lowestSell];
        Price storage prevPriceNode;
        uint256 currentPrice = lowestSell;
        uint256 prevPrice;
        if (floorPrice < currentPrice) {
            currentPriceNode.leftPrice = floorPrice;
            sell.priceNode.parentPrice = currentPrice;
            if (_priceNodeExists(prevPriceNode)) {
                sell.priceNode.leftPrice = prevPrice;
                prevPriceNode.parentPrice = floorPrice;
            }
        }
        

        if (floorPrice < lowestSell) lowestSell = floorPrice;
        // create priceNode, set lowestSell
        

    }

    function _priceNodeExists (
        PriceWithOrders storage priceWithOrders
    ) private view returns(bool) {
        return priceWithOrders.priceNode.headOrderOwner != address(0);
    }

    function _orderExists(
        PriceWithOrders storage priceWithOrders,
        address owner
    ) private view returns(bool, Order storage) {
        Order storage order = priceWithOrders.orders[owner];
        return (order.amount != 0, order);
    }

    function _placeBuyOrder (
        address from,
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) internal virtual returns (bool) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        require(msg.value == (ceilingPrice * amount), "Incorrect fund sent.")

        // Remove sells
        // Close positions (maybe before remove?)
        //   Send securities to asker
        //   Send money to bidder
        // Add rest buys
    }
}