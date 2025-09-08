import { network } from "hardhat";
import { describe, it } from "node:test";
import { networkConfig, developmentChains } from "../helper-hardhat-config.ts";
import assert from "node:assert";
import { expect } from "chai";
const { viem } = await network.connect();
import { getAddress } from "viem";
const publicClient = await viem.getPublicClient();
const chainId = await publicClient.getChainId();
const networkName = publicClient.chain.name.toLowerCase();
const tamagotchi = await viem.getContractAt(
  "Tamagotchi",
  `0x${networkConfig[chainId].contractAddress}`
);

describe("Tamagotchi", function () {
  describe("constuctor", function () {
    it("sets gameplay intervals from the network configuration", async () => {
      expect(Number(await tamagotchi.read.getInterval())).to.equal(
        networkConfig[chainId].interval
      );
      expect(Number(await tamagotchi.read.getGrowthInterval())).to.equal(
        networkConfig[chainId].growthInterval
      );
      expect(
        Number(await tamagotchi.read.getHungerToleranceInterval())
      ).to.equal(networkConfig[chainId].hungerToleranceInterval);
      expect(Number(await tamagotchi.read.getSadToleranceInterval())).to.equal(
        networkConfig[chainId].sadToleranceLevel
      );
      expect(
        Number(await tamagotchi.read.getStinkyToleranceInterval())
      ).to.equal(networkConfig[chainId].stinkyToleranceLevel);
      expect(
        Number(await tamagotchi.read.getBoredToleranceInterval())
      ).to.equal(networkConfig[chainId].boredToleranceLevel);
      expect(
        Number(await tamagotchi.read.getSleepToleranceInterval())
      ).to.equal(networkConfig[chainId].sleepToleranceLevel);
    });

    it("applies decay rates correctly from the network configuration", async () => {
      expect(await tamagotchi.read.getHungerDecayRatePerSecond()).to.equal(
        networkConfig[chainId].hungerDecayRatePerSecond
      );
      expect(await tamagotchi.read.getHappinessDecayRatePerSecond()).to.equal(
        networkConfig[chainId].happinessDecayRatePerSecond
      );
      expect(await tamagotchi.read.getEnergyDecayRatePerSecond()).to.equal(
        networkConfig[chainId].energyDecayRatePerSecond
      );
      expect(await tamagotchi.read.getFunDecayRatePerSecond()).to.equal(
        networkConfig[chainId].funDecayRatePerSecond
      );
      expect(await tamagotchi.read.getHygieneDecayRatePerSecond()).to.equal(
        networkConfig[chainId].hygieneDecayRatePerSecond
      );
    });

    it("configures Chainlink VRF variables from the network configuration", async () => {
      if (!developmentChains.includes(networkName))
        expect(await tamagotchi.read.getSubscriptionId()).to.equal(
          Number(networkConfig[chainId].subscriptionId)
        );
      expect(await tamagotchi.read.getVrfCoordinator()).to.equal(
        networkConfig[chainId].vrfCoordinator
      );
      expect(await tamagotchi.read.getKeyHash()).to.equal(
        networkConfig[chainId].keyHash
      );
      expect(await tamagotchi.read.getCallbackGasLimit()).to.equal(
        Number(networkConfig[chainId].callbackGasLimit)
      );
    });

    it("assigns the correct image URIs for each pet state", async () => {
      expect(await tamagotchi.read.getHappyImageUri()).to.include(
        "mypinata.cloud/ipfs/"
      );
      expect(await tamagotchi.read.getSadImageUri()).to.include(
        "mypinata.cloud/ipfs/"
      );
      expect(await tamagotchi.read.getNeutralImageUri()).to.include(
        "mypinata.cloud/ipfs/"
      );
      expect(await tamagotchi.read.getHungryImageUri()).to.include(
        "mypinata.cloud/ipfs/"
      );
      expect(await tamagotchi.read.getBoredImageUri()).to.include(
        "mypinata.cloud/ipfs/"
      );
      expect(await tamagotchi.read.getStinkyImageUri()).to.include(
        "mypinata.cloud/ipfs/"
      );
    });

    it("starts with tokenCounter and lastProcessedTokenId at 0", async () => {
      expect(Number(await tamagotchi.read.getTokenCounter())).to.equal(0);
      expect(Number(await tamagotchi.read.getLastProcessedTokenId())).to.equal(
        0
      );
    });

    it("assigns the deployer as the initial contract owner", async () => {
      const [deployer] = await viem.getWalletClients();
      expect(getAddress(await tamagotchi.read.getOwner())).to.equal(
        getAddress(deployer.account.address)
      );
    });
  });
});
