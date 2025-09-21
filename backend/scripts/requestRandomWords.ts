import { network } from "hardhat";
const { viem } = await network.connect();

async function main() {
  const tamagotchiAddress = "0xfae57c587d93b08ebdf96397b1e5e44a6980e093";

  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  const tamagotchi = await viem.getContractAt("Tamagotchi", tamagotchiAddress, {
    client: { public: publicClient, wallet: walletClient },
  });

  console.log("Calling requestRandomWords...");
  const txHash = await tamagotchi.write.requestRandomWords();
  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
  });

  console.log("Transaction mined:", receipt.transactionHash);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
