// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ExchangeToken is ERC20 {
    constructor() ERC20("RedToken", "RED") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
}