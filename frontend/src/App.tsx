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
import PetPage from "./components/petPage";
import InstructionPage from "./components/instructionPage";

type ContractConfig = {
  address: Address;
  abi: Abi;
};

function App() {
  const [contractConfig, setContractConfig] = useState<ContractConfig>();
  const [isLoading, setIsLoading] = useState(false);
  const [imageUri, setimageUri] = useState("");
  const [happiness, setHappiness] = useState(0);
  const [hunger, setHunger] = useState(0);
  const [cleanliness, setCleanliness] = useState(0);
  const [entertainment, setEntertainment] = useState(0);
  const [energy, setEnergy] = useState(0);

  const { address, isConnected } = useAccount();
  const chainId = useChainId({ config });

  const { data: tokenCounter, refetch: refetchTokenCounter } = useReadContract({
    ...contractConfig,
    functionName: "getTokenCounter",
    chainId,
  });

  const { data: tokenId, refetch: refetchTokenId } = useReadContract({
    ...contractConfig,
    functionName: "getOwnerToTokenId",
    chainId,
  });

  const { data: petName, refetch: refetchPetName } = useReadContract({
    ...contractConfig,
    functionName: "getTokenIdToPetsName",
    args: [tokenId],
    chainId,
  });

  const { data: tokenUri, refetch: refetchTokenUri } = useReadContract({
    ...contractConfig,
    functionName: "tokenURI",
    args: [tokenId],
    chainId,
  });

  const { data: petStage, refetch: refetchPetStage } = useReadContract({
    ...contractConfig,
    functionName: "getTokenIdToPetStage",
    args: [tokenId],
    chainId,
  });

  const { data: petState, refetch: refetchPetState } = useReadContract({
    ...contractConfig,
    functionName: "getTokenIdToPetState",
    args: [tokenId],
    chainId,
  });

  const { data: petStats, refetch: refetchPetStats } = useReadContract({
    ...contractConfig,
    functionName: "getTokenIdToPetStats",
    args: [tokenId],
    chainId,
  });

  const { data: petAge, refetch: refetchPetAge } = useReadContract({
    ...contractConfig,
    functionName: "getTokenIdToPetsAge",
    args: [tokenId],
    chainId,
  });

  const refetchData = () => {
    refetchTokenCounter();
    refetchPetName();
    refetchTokenId();
    refetchTokenUri();
    refetchPetStage();
    refetchPetState();
    refetchPetStats();
    refetchPetAge();
  };

  useEffect(() => {
    const tempContractConfig = wagmiContractConfig(chainId);
    setContractConfig(tempContractConfig);
  }, [chainId]);

  useEffect(() => {
    refetchData();
  }, [contractConfig, chainId, tokenId, address]);

  useEffect(() => {
    if (!petStats) return;
    const stats = Object(petStats);
    setHappiness(stats["happiness"]);
    setHunger(stats["hunger"]);
    setCleanliness(stats["cleanliness"]);
    setEntertainment(stats["entertainment"]);
    setEnergy(stats["energy"]);
  }, [petStats]);

  useEffect(() => {
    try {
      const base64 = String(tokenUri).split(",")[1];
      const json = JSON.parse(atob(base64));
      setimageUri(json.image);
    } catch (err) {
      console.log(err);
    }
  }, [tokenUri]);

  useWatchBlockNumber({
    enabled: true,
    onBlockNumber: async (blockNumber) => {
      refetchData();
      setIsLoading(false);
    },
    onError(error) {
      console.error("Block error", error);
    },
  });

  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/"
          element={
            <HomePage petName={petName as string} setIsLoading={setIsLoading} />
          }
        />
        <Route
          path="/name"
          element={
            <NamePage
              contractConfig={contractConfig}
              address={address}
              isLoading={isLoading}
              setIsLoading={setIsLoading}
              config={config}
              chainId={chainId}
              petName={petName as string}
            />
          }
        />
        <Route
          path="/pet"
          element={
            <PetPage
              contractConfig={contractConfig}
              address={address}
              isLoading={isLoading}
              setIsLoading={setIsLoading}
              config={config}
              chainId={chainId}
              petName={petName as string}
              imageUri={imageUri}
              tokenId={tokenId as number}
              petStage={petStage as number}
              petState={petState as number}
              happiness={happiness}
              hunger={hunger}
              cleanliness={cleanliness}
              entertainment={entertainment}
              energy={energy}
              petAge={petAge as number}
            />
          }
        />
        <Route
          path="/instructions"
          element={<InstructionPage setIsLoading={setIsLoading} />}
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
