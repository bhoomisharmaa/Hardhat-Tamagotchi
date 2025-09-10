import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, hardhat } from "wagmi/chains";
import { http } from "wagmi";

export const config = getDefaultConfig({
  appName: "Tamagotchi",
  projectId: import.meta.env.VITE_WALLETCONNECT_PROJECT_ID ?? "",
  chains: [sepolia, hardhat],
  transports: {
    [sepolia.id]: http(import.meta.env.VITE_SEPOLIA_RPC_URL),
    [hardhat.id]: http("http://127.0.0.1:8545/"),
  },
  ssr: true,
});
