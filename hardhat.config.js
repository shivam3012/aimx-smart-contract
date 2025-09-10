require('hardhat-abi-exporter')
require('dotenv').config()
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: "paris"
    }
  },

  abiExporter: {
    path: './abis',
    clear: true,
    flat: true,
    runOnCompile: true,
    spacing: 2
  },

  networks: {
    base: {
      chainId: 8453,
      url: process.env.BASE_HTTP,
      accounts: [`0x${process.env.PRIVATE_KEY_BASE}`],
    }
  }
};
