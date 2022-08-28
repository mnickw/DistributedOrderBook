pragma solidity ^0.8.2;

interface IDistributedExchange {
    function placeLimitBid(
        address securityContractAddr,
        uint32 amount,
        uint256 floorPrice
    ) external virtual override returns (bool);

    function placeLimitAsk(
        address securityContractAddr
        uint32 amount,
        uint256 ceilingPrice
    ) external virtual override returns (bool);
}