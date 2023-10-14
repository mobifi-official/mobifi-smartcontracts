require("@nomiclabs/hardhat-ethers");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",

  networks: {
    mainnet: {
      url: "xxxx",
      accounts: ["xxxxx"]
    },
    // ... other networks
  },
  etherscan: {
    // Your Etherscan API key (or Polygonscan, BscScan, etc.)
    apiKey: "xxxx"
  }


};




