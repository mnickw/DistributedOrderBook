const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Depositary", function () {
  async function deployContractsFixture() {
    const Depositary = await ethers.getContractFactory("Depositary");
    const depositary = await Depositary.deploy();
    await depositary.deployed();

    const TestSecurityToken = await ethers.getContractFactory("TestSecurityToken");
    const testSecurityToken = await TestSecurityToken.deploy();
    await testSecurityToken.deployed();

    const [owner, validUserAccount1, validUserAccount2, invalidUserAccount] = await ethers.getSigners();

    // ValidationStatus enum
    const invalidStatus = ethers.BigNumber.from("0");
    const validStatus = ethers.BigNumber.from("1");

    await depositary.setSecurityContractValidationStatus(testSecurityToken.address, validStatus);
    await depositary.setUserValidationStatus(owner.address, validStatus);
    await depositary.setUserValidationStatus(validUserAccount1.address, validStatus);
    await depositary.setUserValidationStatus(validUserAccount2.address, validStatus);

    return { depositary, testSecurityToken, invalidStatus, validStatus,
        owner, validUserAccount1, validUserAccount2, invalidUserAccount };
  }

  describe("getSecurityContractValidationStatus", function () {
    it("Should get valid for TestSecurityToken", async function () {
      const { depositary, testSecurityToken, validStatus } = await loadFixture(deployContractsFixture);
      expect(await depositary.getSecurityContractValidationStatus(testSecurityToken.address)).to.equal(validStatus);
    });

    it("Should get invalid for depository contract address", async function () {
      const { depositary, invalidStatus } = await loadFixture(deployContractsFixture);
      expect(await depositary.getSecurityContractValidationStatus(depositary.address)).to.equal(invalidStatus);
    });
  });

  describe("getUserValidationStatus", function () {
    it("Should get valid for valid user", async function () {
      const { depositary, validUserAccount1, validStatus } = await loadFixture(deployContractsFixture);
      expect(await depositary.getUserValidationStatus(validUserAccount1.address)).to.equal(validStatus);
    });
    
    it("Should get invalid for invalid user", async function () {
      const { depositary, invalidUserAccount, invalidStatus } = await loadFixture(deployContractsFixture);
      expect(await depositary.getUserValidationStatus(invalidUserAccount.address)).to.equal(invalidStatus);
    });
  });

  describe("setSecurityContractValidationStatus", function () {
    describe("testSecurityToken.address, invalidStatus", function () {
      it("Should set to invalid", async function () {
        const { depositary, testSecurityToken, invalidStatus } = await loadFixture(deployContractsFixture);
        await expect(depositary.setSecurityContractValidationStatus(testSecurityToken.address, invalidStatus))
          .not.to.be.reverted;
        expect(await depositary.getSecurityContractValidationStatus(testSecurityToken.address))
          .to.equal(invalidStatus);
      });
    });
    
    describe("testSecurityToken.address, validStatus", function () {
      it("Should remain valid", async function () {
        const { depositary, testSecurityToken, validStatus } = await loadFixture(deployContractsFixture);
        await expect(depositary.setSecurityContractValidationStatus(testSecurityToken.address, validStatus))
          .not.to.be.reverted;
        expect(await depositary.getSecurityContractValidationStatus(testSecurityToken.address))
          .to.equal(validStatus);
      });
    });

    describe("depository.address, invalidStatus", function () {
      it("Should remain invalid", async function () {
        const { depositary, testSecurityToken, invalidStatus } = await loadFixture(deployContractsFixture);
        await expect(depositary.setSecurityContractValidationStatus(depositary.address, invalidStatus))
          .not.to.be.reverted;
        expect(await depositary.getSecurityContractValidationStatus(depositary.address))
          .to.equal(invalidStatus);
      });
    });
  });

  describe("setUserValidationStatus", function () {
    describe("validUserAccount1.address, invalidStatus", function () {
      it("Should set to invalid", async function () {
        const { depositary, validUserAccount1, invalidStatus } = await loadFixture(deployContractsFixture);
        await expect(depositary.setUserValidationStatus(validUserAccount1.address, invalidStatus))
          .not.to.be.reverted;
        expect(await depositary.getUserValidationStatus(validUserAccount1.address))
          .to.equal(invalidStatus);
      });
    });

    describe("validUserAccount1.address, validStatus", function () {
      it("Should remain valid", async function () {
        const { depositary, validUserAccount1, validStatus } = await loadFixture(deployContractsFixture);
        await expect(depositary.setUserValidationStatus(validUserAccount1.address, validStatus))
          .not.to.be.reverted;
        expect(await depositary.getUserValidationStatus(validUserAccount1.address))
          .to.equal(validStatus);
      });
    });

    describe("invalidUserAccount.address, invalidStatus", function () {
      it("Should remain invalid", async function () {
        const { depositary, invalidUserAccount, invalidStatus } = await loadFixture(deployContractsFixture);
        await expect(depositary.setUserValidationStatus(invalidUserAccount.address, invalidStatus))
          .not.to.be.reverted;
        expect(await depositary.getUserValidationStatus(invalidUserAccount.address))
          .to.equal(invalidStatus);
      });
    });
  });
});