pragma solidity ^0.8.2;

interface ILimitOrderBook {
    function placeSellOrder(
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external virtual override returns (bool);

    function placeBuyOrder(
        address securityContractAddr
        uint32 amount,
        uint256 ceilingPrice
    ) external payable virtual override returns (bool);
}