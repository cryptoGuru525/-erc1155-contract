// require('@nomicfoundation/hardhat-toolbox')
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      { version: "0.8.3" }
      // { version: "0.7.6" },
      // { version: "0.6.12" },
      // { version: "0.5.17" }
    ]
  },
  paths: {
    artifacts: "./artifacts"
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
      live: false,
      gasMultiplier: 2,
      allowUnlimitedContractSize: true
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
      live: false,
      gasMultiplier: 2,
      allowUnlimitedContractSize: true
    }
  },
  etherscan: {
    apiKey: "2RJNBPSPJ8MM9FABDZJCHP5JGBY2PB7JAE" //  'RNG9JSM1TR9H5MW2QYCJQCMNYNSHU24JW7',
  }
};
