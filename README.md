# Deployment
Do `npm install` in the cloned directory.

This project supports both Truffle and Hardhat, but tests are written for Hardhat. Choose whatever you want.

For frontend development with Hardhat use [this guide](https://hardhat.org/tutorial/boilerplate-project) as a reference.

For frontend development with Truffle use [this guide](https://trufflesuite.com/guides/pet-shop/) as a reference. Check out the [Drizzle](https://trufflesuite.com/docs/drizzle/) framework also.

If you modify the contract - run tests (`npx hardhat test`), restart the node and deploy contracts again.

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

## Truffle
Start local node:
```
npx ganache
```
Alternatively, you can install Ganache GUI globally to run the node.

Deploy contracts:
```
npx truffle migration
```
If you want to create a token for security, create migrations/2_deploy_testSecurityToken.js (it's also gitignored) with the code below and do `npx truffle migrate` again:
```
var TestSecurityToken = artifacts.require("TestSecurityToken");

module.exports = function(deployer) {
  deployer.deploy(TestSecurityToken);
};
```

## Remix
Alternatively (just for testing functions directly) you can use Remix (and VSCode Remix extension). Click deploy in extension -> Activate -> Connect Remix. Open your Remix in the browser, click workspaces -> connect to localhost.