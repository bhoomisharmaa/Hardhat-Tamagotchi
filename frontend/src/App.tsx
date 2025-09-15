import "./index.css";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { useEffect, useState } from "react";
import {
  useAccount,
  useChainId,
  useReadContract,
  useWatchBlockNumber,
} from "wagmi";
import type { Abi, Address } from "viem";
import { config } from "./utils/wagmiConfig";
import { wagmiContractConfig } from "./utils/contractConfig";
import NamePage from "./components/namePage";
import HomePage from "./components/homePage";

type ContractConfig = {
  address: Address;
  abi: Abi;
};

function App() {
  const [contractConfig, setContractConfig] = useState<ContractConfig>();
  const [isLoading, setIsLoading] = useState(false);

  const { address } = useAccount();
  const chainId = useChainId({ config });

  const { data: tokenCounter, refetch: refetchTokenCounter } = useReadContract({
    ...contractConfig,
    functionName: "getTokenCounter",
    chainId,
  });

  const refetchData = () => {
    refetchTokenCounter();
  };

  useEffect(() => {
    const tempContractConfig = wagmiContractConfig(chainId);
    setContractConfig(tempContractConfig);
    console.log(tempContractConfig);
  }, [chainId]);

  useEffect(() => {
    refetchData();
  }, [contractConfig]);

  useWatchBlockNumber({
    enabled: true,
    onBlockNumber: async () => {
      refetchData();
    },
  });

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route
          path="/name"
          element={
            <NamePage
              contractConfig={contractConfig}
              address={address}
              setIsLoading={setIsLoading}
              config={config}
            />
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
