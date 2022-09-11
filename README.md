# Deployment
Do `npm install` in the cloned directory.

This project supports both Truffle and Hardhat, but tests are written for Hardhat. Choose whatever you want.

## Hardhat
Start local node:
```
npx hardhat node
```
Deploy contracts:
```
npx hardhat run --network localhost scripts/deploy.js
```

If you also want to create a token for security:
```
npx hardhat run --network localhost scripts/deploy_testSecurityToken.js
```

If you modify the contract - run tests (`npx hardhat test`), restart the node and deploy contracts again.

## Truffle
Use [this guide](https://trufflesuite.com/guides/pet-shop/) as a reference. Check out the [Drizzle](https://trufflesuite.com/docs/drizzle/) framework for frontend development also.

TLDR: install Truffle (`npm install -g truffle`) and [Ganache GUI](https://trufflesuite.com/ganache/), run Ganache and do `truffle migrate`.

If you want to create a token for security, create migrations/2_deploy_testSecurityToken (it's also gitignored) with the next code:
```
var TestSecurityToken = artifacts.require("TestSecurityToken");

module.exports = function(deployer) {
  deployer.deploy(TestSecurityToken);
};
```
Do `truffle migrate` (after ganache initialization).

If you modify the contract - run tests (`npx hardhat test`), restart ganache (in settings) and do `truffle migrate`.

## Remix
Alternatively (just for testing functions directly) you can use Remix (and VSCode Remix extension). Click deploy in extension -> Activate -> Connect Remix. Open your Remix in the browser, click workspaces -> connect to localhost.