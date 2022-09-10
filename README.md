## Deployment
Do `npm install`.

Use [this guide](https://trufflesuite.com/guides/pet-shop/) as a reference. Check out the [Drizzle](https://trufflesuite.com/docs/drizzle/) framework also.

If you want to create a token for security, create migrations/2_deploy_test_token.js (it's also gitignored) with the next code:
```
var TestSecurityToken = artifacts.require("TestSecurityToken");

module.exports = function(deployer) {
  deployer.deploy(TestSecurityToken);
};
```
Do `truffle migrate` (after ganache initialization).

If you modify the contract - do `truffle test`, restart ganache (in settings) and do `truffle migrate`.

Alternatively (just for testing functions directly) you can use Remix (and VSCode Remix extension). Click deploy in extension -> Activate -> Connect Remix. Open your Remix in the browser, click workspaces -> connect to localhost.