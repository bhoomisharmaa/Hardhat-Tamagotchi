import { useEffect, useState } from "react";
import type { Address, Abi } from "viem";
import { waitForTransactionReceipt } from "viem/actions";
import { useAccount, useBalance, useWriteContract } from "wagmi";

type ContractConfig = {
  address: Address;
  abi: Abi | readonly unknown[];
};

interface PetPageProps {
  contractConfig?: ContractConfig;
  address?: Address;
  config: any;
  setIsLoading: (loading: boolean) => void;
  chainId: 11155111 | 31337;
  petName: string;
  imageUri: string;
  tokenId: number;
  petStage: number;
  petState: number;
  happiness: number;
  hunger: number;
  cleanliness: number;
  entertainment: number;
  energy: number;
  petAge: number;
}

export default function PetPage({
  contractConfig,
  address,
  config,
  setIsLoading,
  chainId,
  petName,
  imageUri,
  tokenId,
  petStage,
  petState,
  happiness,
  hunger,
  cleanliness,
  entertainment,
  energy,
  petAge,
}: PetPageProps) {
  const account = useAccount();
  const { writeContractAsync } = useWriteContract();
  const petStageArr = ["BABY", "TEEN", "ADULT"];
  const petStateArr = [
    "HAPPY",
    "SAD",
    "NEUTRAL",
    "HUNGRY",
    "BORED",
    "STINKY",
    "LETHARGIC",
    "DEAD",
  ];
  const actions = ["FEED", "PLAY", "CUDDLE", "BATHE", "SLEEP"];

  const handleInteraction = async (action: string) => {
    try {
      const txn = await writeContractAsync({
        ...contractConfig!,
        functionName: action,
        args: [tokenId],
        chainId,
        account: address!,
      });
      setIsLoading(true);
      const receipt = await waitForTransactionReceipt(config, { hash: txn });
      console.log("Receipt:", receipt);
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <div className="h-screen w-screen bg-alice-blue flex items-center justify-center font-tiny5">
      <div className="h-max w-max md:p-6 sm:p-4 p-3 sm:border-3 border-2">
        <div className="h-max w-max sm:border-3 border-2 border-dashed md:px-10 md:py-7 sm:px-6 sm:py-4 px-3 py-2 flex flex-col sm:gap-6 gap-1 items-center font-pressStart">
          <div className="h-max w-full flex items-center gap-10 justify-between sm:text-base xs:text-[10px] xxs:text-[8px] text-[6px]">
            <p>{`Token ID:${tokenId}`}</p>
            <p>
              {account.address?.slice(0, 6) +
                "....." +
                account.address?.slice(38)}
            </p>
          </div>
          <div className="flex flex-col items-center md:text-2xl sm:text-xl xs:text-lg xxs:text-sm text-sm">
            <p>{petName}</p>
            <img src={imageUri} className="md:h-30 sm:h-25 aspect-sqaure" />
          </div>
          <div className="flex items-center md:gap-20 sm:gap-15 xs:gap-10 gap-5 font-tiny5 lg:text-2xl sm:text-xl xs:text-lg text-sm">
            <div className="flex flex-col gap-2 items-end">
              <p>STAGE: {petStageArr[petStage]}</p>
              <p>HAPPINESS: {happiness}</p>
              <p>CLEANINESS: {cleanliness}</p>
              <p>ENERGY: {energy}</p>
            </div>
            <div className="flex flex-col gap-2 items-start">
              <p>STATE: {petStateArr[petState]}</p>
              <p>HUNGER: {hunger}</p>
              <p>ENTERTAINMENT: {entertainment}</p>
              <p>AGE: {petAge}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 font-tiny5 mt-4">
            {actions.map((action) => (
              <button
                onClick={() => handleInteraction(action.toLowerCase())}
                className="bg-blue-grey sm:px-3 sm:py-1 px-2 py-1 sm:border-2 border-1 sm:rounded-2xl rounded-md md:text-xl sm:text-sm xs:text-xs text-[7px]"
              >
                {action}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
