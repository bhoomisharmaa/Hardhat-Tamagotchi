import * as dotenv from "dotenv";
dotenv.config();

const networkConfig = {
  11155111: {
    name: "sepolia",
    vrfCoordinator: "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B",
    keyHash:
      "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae",
    callbackGasLimit: "500000",
    subscriptionId: process.env.SUBSCRIPTION_ID,
    interval: 7200,
    hungerDecayRatePerSecond: 578703703703700,
    happinessDecayRatePerSecond: 385802469135802,
    energyDecayRatePerSecond: 289351851851851,
    funDecayRatePerSecond: 231481481481481,
    hygieneDecayRatePerSecond: 192901234567901,
    growthInterval: 86400,
    hungerToleranceInterval: 57600,
    sadToleranceLevel: 86400,
    stinkyToleranceLevel: 115200,
    boredToleranceLevel: 86400,
    sleepToleranceLevel: 115200,
  },
  31337: {
    name: "localhost",
    keyHash:
      "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
    callbackGasLimit: "500000",
    subscriptionId: process.env.SUBSCRIPTION_ID,
    interval: 120,
    hungerDecayRatePerSecond: 66666666666666666667n,
    happinessDecayRatePerSecond: 5000000000000000000n,
    energyDecayRatePerSecond: 3333333333333333333n,
    funDecayRatePerSecond: 2500000000000000000n,
    hygieneDecayRatePerSecond: 1666666666666666666n,
    growthInterval: 300,
    hungerToleranceInterval: 120,
    sadToleranceLevel: 180,
    stinkyToleranceLevel: 240,
    boredToleranceLevel: 180,
    sleepToleranceLevel: 240,
  },
};

const developmentChains = ["localhost", "hardhat"];

module.exports = { networkConfig, developmentChains };
