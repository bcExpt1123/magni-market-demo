const path = require('path')
require('@nomiclabs/hardhat-waffle')
require('dotenv').config({ path: path.join(__dirname, '/.env.local') })
require('hardhat-gas-reporter')
require("@nomiclabs/hardhat-etherscan")

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: [`${process.env.ACCOUNT_PRIVATE_KEY}`, `${process.env.ACCOUNT2_PRIVATE_KEY}`],
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY, process.env.ACCOUNT2_PRIVATE_KEY],
      gas: 5500000,
      chainId: 1337,
      gasPrice: 7000000000
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`,
      chainId: 1337,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY, process.env.ACCOUNT2_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      avalancheFujiTestnet: process.env.SNOWSCAN_API_KEY,
    },
  },
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
