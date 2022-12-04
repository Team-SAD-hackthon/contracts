require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-change-network");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    polygon: {
      url: `https://polygon-rpc.com`,
      accounts: [process.env.PRIVATE_KEY],
    },
    arbitrum: {
      url: 'https://arb1.arbitrum.io/rpc',
      accounts: [process.env.PRIVATE_KEY],
    },
    optimism: {
      url: 'https://mainnet.optimism.io/',
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
