const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Order book", function () {
  async function deployContractsFixture() {
    const Depositary = await ethers.getContractFactory("Depositary");
    const depositary = await Depositary.deploy();
    await depositary.deployed();

    const TestSecurityToken = await ethers.getContractFactory("TestSecurityToken");
    const testSecurityToken = await TestSecurityToken.deploy();
    await testSecurityToken.deployed();

    const [owner, asker1, asker2, unapprovedAsker,
      bidder1, bidder2, unapprovedBidder,
      invalidUserAccount] = await ethers.getSigners();

    // ValidationStatus enum
    const invalidStatus = ethers.BigNumber.from("0");
    const validStatus = ethers.BigNumber.from("1");

    depositary.setSecurityContractValidationStatus(testSecurityToken.address, validStatus);
    depositary.setUserValidationStatus(owner.address, validStatus);
    depositary.setUserValidationStatus(asker1.address, validStatus);
    depositary.setUserValidationStatus(asker2.address, validStatus);
    depositary.setUserValidationStatus(unapprovedAsker.address, validStatus);
    depositary.setUserValidationStatus(bidder1.address, validStatus);
    depositary.setUserValidationStatus(bidder2.address, validStatus);
    depositary.setUserValidationStatus(unapprovedBidder.address, validStatus);

    const ExchangeToken = await ethers.getContractFactory("ExchangeToken");
    const exchangeToken = await ExchangeToken.deploy();
    await exchangeToken.deployed();

    const OrderBookLinkedList = await ethers.getContractFactory("OrderBookLinkedList");
    const orderBookLinkedList = await OrderBookLinkedList.deploy(exchangeToken.address, depositary.address);
    await orderBookLinkedList.deployed();

    await testSecurityToken.connect(owner).transfer(asker1.address, 200);
    await testSecurityToken.connect(owner).transfer(asker2.address, 300);
    await testSecurityToken.connect(asker1).approve(orderBookLinkedList.address, 150);
    await testSecurityToken.connect(asker2).approve(orderBookLinkedList.address, 250);

    await exchangeToken.connect(owner).transfer(bidder1.address, 100);
    await exchangeToken.connect(owner).transfer(bidder2.address, 200);
    await exchangeToken.connect(bidder1).approve(orderBookLinkedList.address, 50);
    await exchangeToken.connect(bidder2).approve(orderBookLinkedList.address, 150);

    // PlaceOrderStatus enum
    const filledStatus = ethers.BigNumber.from("0");
    const placedStatus = ethers.BigNumber.from("1");
    const partiallyFilledAndPlacedStatus = ethers.BigNumber.from("2");

    return { depositary, testSecurityToken, exchangeToken, orderBookLinkedList,
      invalidStatus, validStatus,
      filledStatus, placedStatus, partiallyFilledAndPlacedStatus,
      owner, asker1, asker2, bidder1, bidder2, unapprovedAsker, invalidUserAccount };
  }

  describe("placeLimitAskOrder", function () {
    describe("valid params", function () {
      describe("no existing bids, no existing asks", function () {
        it("Should emit DrawToOrderBook", async function () {
          const { orderBookLinkedList, testSecurityToken, asker1 } = await loadFixture(deployContractsFixture);
          await expect(orderBookLinkedList.connect(asker1).placeLimitAskOrder(testSecurityToken.address, 140, 42))
            .to.emit(orderBookLinkedList, "DrawToOrderBook")
            .withArgs(testSecurityToken.address, asker1.address, false, 140, 42);
        });
        // should change balance
        // changes lowerAsk
      });
      // exists: 1 bid; used: 0 bids -> placed
      // exists: 1 multiple-ordered bid (2 or 3 orders); used: 0 bids -> placed
      // exists: 1 bid; used: 1 bid -> filled
      // exists: 1 bid, request amount is less than in bid; used: 1 bid partly -> filled
      // exists: 1 multiple-ordered bid (2 or 3 orders); used: 1 bid with all orders -> filled
      // exists: 1 multiple-ordered (2 or 3 orders) bid, 1-nd order has request amount; used: only 1-st order of bid -> filled
      // exists: 1 multiple-ordered (3 or 4 orders) bid, 2-nd order has required rest amount; used: only 2 orders of bid -> filled
      // exists: 1 multiple-ordered (2 or 3 orders) bid, 1-nd order has more than request amount; used: partly 1-st order of bid -> filled
      // exists: 1 multiple-ordered (2 or 3 orders) bid, 2-nd order has more than required rest amount; used: 1-st whole order and partly 2-nd order of bid -> filled

      // same as above tests, but was additional not used 2-nd bid
      // same as above tests, but was additional not used 2-nd multiple-ordered bid (2 or 3 orders)

      // same as above tests, but was additional not used 3-rd bid
      // same as above tests, but was additional not used 3-rd multiple-ordered bid (2 or 3 orders)

      // exists: 1 bid, request amount is bigger than in bid; used: 1 bid -> partiallyFilledAndPlaced
      // exists: 1 multiple-ordered (2 or 3 orders) bid; used: all orders, not enough to be fully filled -> partiallyFilledAndPlaced

      // 2 bids
      // 3 bids

      // for every test above test different existing asks
    });
    // invalid security
    // invalid user
    // not approved user
    // == 0
    // TODO: overflow
  });
  // place bid
  // cancel
});