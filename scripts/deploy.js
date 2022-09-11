// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const ExchangeToken = await hre.ethers.getContractFactory("ExchangeToken");
  const exchangeToken = await ExchangeToken.deploy();
  await exchangeToken.deployed();
  const Depositary = await hre.ethers.getContractFactory("Depositary");
  const depositary = await Depositary.deploy();
  await depositary.deployed();
  const OrderBookLinkedList = await hre.ethers.getContractFactory("OrderBookLinkedList");
  const orderBookLinkedList = await Lock.deploy(exchangeToken.address, depositary.address);
  await orderBookLinkedList.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
