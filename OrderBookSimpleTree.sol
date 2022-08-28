pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract OrderBookSimpleTree is IOrderBook {
    using SafeERC20 for IERC20;

    struct Order {
        address payable owner;
        uint32 amount;
        uint256 nextOrderId;
    }

    struct Price {
        uint256 parentPrice;
        uint256 leftPrice;
        uint256 rightPrice;
        uint256 headOrderId;
    }

    mapping(address => mapping(uint256 => Price)) internal sellPriceNodes; // securityContract => (price => Price))
    mapping(address => mapping(uint256 => Price)) internal buyPriceNodes; // securityContract => (price => Price))
    mapping(uint256 => Order) internal orders; // orderId => Order
    uint256 lowestSell internal;
    uint256 highestBuy internal;

    constructor() {
        // TODO: Initialize depo contract
    }

    // TODO: Cancel order
    // TODO: Approved orders

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

        // Remove buys
        // Close positions (maybe before remove?)
        //   Send securities to asker
        //   Send money to bidder
        // Add rest sells
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