var ExchangeToken = artifacts.require("ExchangeToken");
var Depositary = artifacts.require("Depositary");
var OrderBookLinkedList = artifacts.require("OrderBookLinkedList");

module.exports = async function(deployer) {
  await deployer.deploy(ExchangeToken);
  const exchangeTokenAddress = (await ExchangeToken.deployed()).address;
  await deployer.deploy(Depositary);
  const depositaryAddress = (await Depositary.deployed()).address;
  await deployer.deploy(OrderBookLinkedList, exchangeTokenAddress, depositaryAddress);
};