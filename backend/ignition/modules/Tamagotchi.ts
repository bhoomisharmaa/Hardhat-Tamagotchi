import { buildModule } from "@nomicfoundation/ignition-core";
import { network } from "hardhat";
import {
  networkConfig,
  developmentChains,
} from "../../helper-hardhat-config.ts";

const { ethers } = await network.connect();
const connectedNetwork = await ethers.provider.getNetwork();

export default buildModule("Tamagotchi", (m) => {
  let vrfCoordinator, subscriptionId;

  const chainId = Number(connectedNetwork.chainId);
  const networkName = connectedNetwork.name;

  // Image URI
  const happyImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreigsmxovabg3tszcj4kd4lyfoesjk5k4szr2yayqfb46endif67b5u";
  const sadImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreifmte3p7v2wr6xgocvmkdkbrazqzvw2dvwbqj27xxjbm566nn6d4a";
  const neutralImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreiewmm2zdidrabxyeqedfor4tu3utnmcultzbtx3uzmdezngjzbacm";
  const hungryImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreid3apinl4sygihf6j4yutstxckypf32vglozaidcpfr3jn7niphyq";
  const boredImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreibax2wix5dolg2ykfsskrloufpocdtgsyhxb7kemlfv2xitbgac2e";
  const stinkyImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreifa3my5pm34xjthggfecym5a54jfvc43qjhwaktjzznkegq7crez4";
  const lethargicImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreigdvmsvmhl4x5y4y2l5q3ncu7rtcsadvwimb2lq6w5svsatfo73ca";
  const deadImageUri =
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreibw2562c7p7e5lgfb5ub6bz3yqumufxxtcptjzz4zra7nug7y7nku";

  if (developmentChains.includes(networkName)) {
    const BASE_FEE = "250000000000000000";
    const GAS_PRICE_LINK = 1e9;
    const WEI_PER_UNIT_LINK = "1000000000000000000";
    const FUND_AMT = "10000000000000000000";

    vrfCoordinator = m.contract("MyVRFCoordinatorV2_5Mock", [
      BASE_FEE,
      GAS_PRICE_LINK,
      WEI_PER_UNIT_LINK,
    ]);

    const createSub = m.call(vrfCoordinator, "createSubscription", []);
    subscriptionId = m.readEventArgument(
      createSub,
      "SubscriptionCreated",
      "subId"
    );

    m.call(vrfCoordinator, "fundSubscription", [subscriptionId, FUND_AMT]);
  } else {
    const vrfCoordinatorAddress =
      networkConfig[chainId].vrfCoordinator ??
      "0x0000000000000000000000000000000000000000";
    vrfCoordinator = m.contractAt("VRFCoordinatorV2_5", vrfCoordinatorAddress);
    subscriptionId = networkConfig[chainId].subscriptionId;
  }

  const args = [
    networkConfig[chainId].interval,
    networkConfig[chainId].hungerDecayRatePerSecond,
    networkConfig[chainId].happinessDecayRatePerSecond,
    networkConfig[chainId].energyDecayRatePerSecond,
    networkConfig[chainId].funDecayRatePerSecond,
    networkConfig[chainId].hygieneDecayRatePerSecond,
    networkConfig[chainId].growthInterval,
    networkConfig[chainId].hungerToleranceInterval,
    networkConfig[chainId].sadToleranceLevel,
    networkConfig[chainId].stinkyToleranceLevel,
    networkConfig[chainId].boredToleranceLevel,
    networkConfig[chainId].sleepToleranceLevel,
    subscriptionId ?? "0",
    vrfCoordinator ?? "0x0000000000000000000000000000000000000000",
    networkConfig[chainId].keyHash,
    networkConfig[chainId].callbackGasLimit,
    happyImageUri,
    sadImageUri,
    neutralImageUri,
    hungryImageUri,
    boredImageUri,
    stinkyImageUri,
    lethargicImageUri,
    deadImageUri,
  ];
  const tamagotchi = m.contract("Tamagotchi", args);
  m.call(vrfCoordinator, "addConsumer", [subscriptionId!, tamagotchi]);
  m.call(tamagotchi, "requestRandomWords", []);
  return { tamagotchi };
});
