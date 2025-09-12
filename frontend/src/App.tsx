import "@rainbow-me/rainbowkit/styles.css";
import "./index.css";
import { WagmiProvider } from "wagmi";
import { config } from "./utils/wagmiConfig";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import HomePage from "./components/homePage";

const queryClient = new QueryClient();

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <div className="h-screen w-screen bg-(--color-alice-blue) cursor-(--pixel-cursor)">
            <HomePage />
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
