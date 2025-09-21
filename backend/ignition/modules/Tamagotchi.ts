import { buildModule } from "@nomicfoundation/ignition-core";
import { network } from "hardhat";
import {
  networkConfig,
  developmentChains,
} from "../../helper-hardhat-config.ts";

const { viem } = await network.connect();
const publicClient = await viem.getPublicClient();
const chainId = await publicClient.getChainId();

export default buildModule("Tamagotchi", (m) => {
  let vrfCoordinator, vrfCoordinatorContract, subscriptionId;
  const networkName = publicClient.chain.name.toLowerCase();

  // Image URI
  const happyImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreigsmxovabg3tszcj4kd4lyfoesjk5k4szr2yayqfb46endif67b5u",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreicfbcxe6hj7tbmgh6rbiuipksg5k5bf2k44jfvvekfdka3lns4fiu",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreigrpyhrr74ds7e7orsgg2kh4zalho2xsngm5dxr367cgs3mq6dwwy",
  ];
  const sadImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreifmte3p7v2wr6xgocvmkdkbrazqzvw2dvwbqj27xxjbm566nn6d4a",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreid6aumxvaznq3fxpmdcnqgqva7btuguawezpsl2rfqu6xlctn6yzu",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreifgxw7pb76j6ym2rvmhqfo57iqpkmkylapdxjejcbrckfywmvgdrq",
  ];
  const neutralImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreiewmm2zdidrabxyeqedfor4tu3utnmcultzbtx3uzmdezngjzbacm",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreibpmrws6mcgbq5zf4jumjzczjbahub3f7axopqxibn5paeioqxuji",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreidug7yol5rdlpzs7nzjdkdxnkcdxpqk5bxni2bauy6vxjp2wqoxge",
  ];
  const hungryImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreid3apinl4sygihf6j4yutstxckypf32vglozaidcpfr3jn7niphyq",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreia5ao3xl5ygih527zga5zr2bkekzjb2bmbamcwhvhfycljgojl5au",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreib6h43narjcdmr77eo3ajlatodlhgtqpffs2yg7d43de7tzz4cit4",
  ];
  const boredImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreibax2wix5dolg2ykfsskrloufpocdtgsyhxb7kemlfv2xitbgac2e",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreidpxzlm5wbb3qpruycxhb6dgqit7z5c43ju3hngxafueaawpp3sjy",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreifdlea3cg26o2sdesjdhkfyoddaigwa5fjpka2ldbxchhelhjfizm",
  ];
  const stinkyImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreifa3my5pm34xjthggfecym5a54jfvc43qjhwaktjzznkegq7crez4",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreiffsatpejny5aksjmrb54i5uopyz2nxdm45jb56tikpe4tvjdjwy4",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreihojbdnphmna7cy2hioa5fk6ahr7i3kkoiptfg64fs6ozggx7h3zq",
  ];
  const lethargicImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreigdvmsvmhl4x5y4y2l5q3ncu7rtcsadvwimb2lq6w5svsatfo73ca",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreiabkptr5kxmsopkwxx45ksm7szbhg5c6zee47mjmvwro3jjdhk6dy",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreicbytwr6w5gjjwj3uqqpdev3b6nedjwz4nhijwtq2dryu3yomwp6q",
  ];
  const deadImageUri = [
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreibw2562c7p7e5lgfb5ub6bz3yqumufxxtcptjzz4zra7nug7y7nku",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreiagg6jxn3fa6sld2h6yx242b3v4jmddk2j5xr6fqamvpmv53mtgoa",
    "https://orange-chemical-monkey-267.mypinata.cloud/ipfs/bafkreidpgno22vj3og6cs3tlbakyikpmpb6rj7z25ech3uekrmziz2lsva",
  ];

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

    vrfCoordinatorContract = vrfCoordinator;

    m.call(vrfCoordinator, "fundSubscription", [subscriptionId, FUND_AMT]);
  } else {
    vrfCoordinator =
      networkConfig[chainId].vrfCoordinator ??
      "0x0000000000000000000000000000000000000000";

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
  if (developmentChains.includes(networkName))
    m.call(vrfCoordinatorContract!, "addConsumer", [
      subscriptionId!,
      tamagotchi,
    ]);
  return { tamagotchi };
});
