import { network } from "hardhat";
import { beforeEach, describe, it } from "node:test";
import { networkConfig, developmentChains } from "../helper-hardhat-config.ts";
import assert from "node:assert";
import { expect } from "chai";
const { viem } = await network.connect();
import { decodeEventLog, getAddress } from "viem";
const publicClient = await viem.getPublicClient();
const chainId = await publicClient.getChainId();
const networkName = publicClient.chain.name.toLowerCase();
const [deployer, imposter] = await viem.getWalletClients();
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
      expect(getAddress(await tamagotchi.read.getOwner())).to.equal(
        getAddress(deployer.account.address)
      );
    });
  });

  describe("mintNft", function () {
    it("should emit Transfer and NftMinted event", async () => {
      const hash = await tamagotchi.write.mintNft();
      const receipt = await publicClient.getTransactionReceipt({ hash });
      const event1 = decodeEventLog({
        abi: tamagotchi.abi,
        data: receipt.logs[0].data,
        topics: receipt.logs[0].topics,
      });
      const event2 = decodeEventLog({
        abi: tamagotchi.abi,
        data: receipt.logs[1].data,
        topics: receipt.logs[1].topics,
      });

      expect(event1.eventName).to.equal("Transfer");
      expect(event2.eventName).to.equal("NftMinted");
    });

    it("should mint a new NFT pet to caller", async () => {
      const owner = await tamagotchi.read.ownerOf([0n]);
      expect(getAddress(owner)).to.equal(getAddress(deployer.account.address));
    });

    it("should set all the intervals", async () => {
      const timestamps = await tamagotchi.read.getTokenIdToPetTimestamps([0n]);
      expect(Number(timestamps.mintedAt)).to.be.greaterThan(0);
      expect(Number(timestamps.bathedAt)).to.be.greaterThan(0);
      expect(Number(timestamps.cuddledAt)).to.be.greaterThan(0);
      expect(Number(timestamps.fedAt)).to.be.greaterThan(0);
      expect(Number(timestamps.grewAt)).to.be.greaterThan(0);
      expect(Number(timestamps.playedAt)).to.be.greaterThan(0);
      expect(Number(timestamps.sleptAt)).to.be.greaterThan(0);
    });

    it("should initialize all the stats correctly", async () => {
      const stats = await tamagotchi.read.getTokenIdToPetStats([0n]);
      expect(stats.hunger).to.equal(30n);
      expect(stats.happiness).to.equal(70n);
      expect(stats.energy).to.equal(70n);
      expect(stats.cleanliness).to.equal(20n);
      expect(stats.entertainment).to.equal(70n);
    });

    it("should increment the token counter", async () => {
      expect(await tamagotchi.read.getTokenCounter()).to.equal(1n);
    });

    it("should initialize the pet's stage as BABY, age as 0, and stage as STINKY", async () => {
      expect(Number(await tamagotchi.read.getTokenIdToPetStage([0n]))).to.equal(
        0
      );
      expect(Number(await tamagotchi.read.getTokenIdToPetsAge([0n]))).to.equal(
        0
      );
      expect(Number(await tamagotchi.read.getTokenIdToPetState([0n]))).to.equal(
        5
      );
    });
  });
});
