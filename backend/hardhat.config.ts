import type { HardhatUserConfig } from "hardhat/config";
import hardhatVerify from "@nomicfoundation/hardhat-verify";
import hardhatIgnition from "@nomicfoundation/hardhat-ignition-viem";
import hardhatViem from "@nomicfoundation/hardhat-viem";
import hardhatNodeTestRunner from "@nomicfoundation/hardhat-node-test-runner";
import { configVariable } from "hardhat/config";

const config: HardhatUserConfig = {
  plugins: [hardhatVerify, hardhatIgnition, hardhatViem, hardhatNodeTestRunner],
  solidity: {
    profiles: {
      default: {
        version: "0.8.28",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      production: {
        version: "0.8.28",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [
        configVariable("PRIVATE_KEY_ACCOUNT_1"),
        configVariable("PRIVATE_KEY_ACCOUNT_2"),
      ],
    },
  },

  verify: {
    etherscan: {
      apiKey: configVariable("ETHERSCAN_API_KEY"),
      enabled: true,
    },
  },
};

export default config;
