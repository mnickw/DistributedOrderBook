pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";

contract DistributedExchange is IDistributedExchange, Context {

    struct OrderNode {
        address owner;
        uint32 amount;
        uint256 nextOrderNodeId;
    }

    struct PriceNode {
        uint256 prevPrice;
        uint256 nextPrice;
        uint256 firstOrderNodeId;
    }

    mapping(address => mapping(uint256 => PriceNode)) internal bids; // securityContract => (price => PriceNode))
    mapping(address => mapping(uint256 => PriceNode)) internal asks; // securityContract => (price => PriceNode))
    mapping(uint256 => OrderNode) internal orders; // orderId => Order

    constructor() {
        // TODO: Initialize depo contract
        // Maybe some code to let available `transferTo` to this contract?
    }

    // TODO: Cancel order
    // TODO: Approved orders

    function placeLimitBid(
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external virtual override returns (bool) {
        _bid(_msgSender(), securityContractAddr, amount, floorPrice);
    }

    function placeLimitAsk(
        address securityContractAddr
        uint32 amount,
        uint256 ceilingPrice
    ) external virtual override returns (bool) {
        _ask(_msgSender(), securityContractAddr, amount, ceilingPrice);
    }

    function _placeLimitBid(
        address from,
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) internal virtual returns (bool) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        // Check if `from` has enough securities.
        // Lock them by making {transferTo} to this contract

        // Chainlink call. It rturns OrderNodeId for asks and OrderNodeId for inserting in bids
        // Remove nodes (from maps too)
        // Close positions (maybe before remove?)
        //   Send securities to asker
        //   Send money to bidder
        // Check second OrderNodeId and insert rest bids
    }

    function _placeLimitAsk(
        address from,
        address securityContractAddr,
        uint32 amount,
        uint256 ceilingPrice
    ) internal virtual returns (bool) {
        // TODO: Check by depo that `securityContractAddr` is valid
        // TODO: Check by depo that `from` is valid

        // Check if `from` has enough money.
        // Lock money by sending them to this contract

        // Chainlink call. It rturns OrderNodeId for bids and OrderNodeId for inserting in asks
        // Remove nodes (from maps too)
        // Close positions (maybe before remove?)
        //   Send securities to asker
        //   Send money to bidder
        // Check second OrderNodeId and insert rest asks
    }
}