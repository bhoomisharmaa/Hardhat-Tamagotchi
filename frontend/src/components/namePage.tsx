import { useEffect, useState } from "react";
import { useAccount, useBalance, useWriteContract } from "wagmi";
import type { Abi, Address } from "viem";
import { waitForTransactionReceipt } from "wagmi/actions";
import LoadingPage from "./loadingPage";
import { useNavigate } from "react-router-dom";

type ContractConfig = {
  address: Address;
  abi: Abi | readonly unknown[];
};

interface NamePageProps {
  contractConfig?: ContractConfig;
  address?: Address;
  config: any;
  isLoading: boolean;
  setIsLoading: (loading: boolean) => void;
  chainId: 11155111 | 31337;
  petName: string;
}

export default function NamePage({
  contractConfig,
  address,
  config,
  isLoading,
  setIsLoading,
  chainId,
  petName,
}: NamePageProps) {
  const [balance, setBalance] = useState("0");
  const [index, setIndex] = useState(0);

  const account = useAccount();
  const navigate = useNavigate();
  const { data } = useBalance({ address: account.address, chainId });
  const { writeContractAsync } = useWriteContract();

  const alreadyMinted = [
    "Trying to replace your pet already? Rude",
    "One pet is enough. You can’t even handle yourself.",
    "Your pet already exists and it’s probably starving. Go feed it.",
  ];

  const handleAdoption = async (e: React.FormEvent<HTMLFormElement>) => {
    try {
      e.preventDefault();
      const formData = new FormData(e.target as HTMLFormElement);
      const name = formData.get("name") as string;
      const txn = await writeContractAsync({
        ...contractConfig!,
        functionName: "mintNft",
        args: [name],
        account: address!,
      });
      setIsLoading(true);
      await waitForTransactionReceipt(config, { hash: txn });
      navigate("/pet");
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  };

  useEffect(() => {
    setIsLoading(false);
    if (petName) {
      setIndex(Math.random() * 3);
    }
  }, []);

  useEffect(() => {
    const value = Number(data?.value);
    const decimal = Math.pow(10, Number(data?.decimals));
    const tempBalance = value / decimal;
    if (tempBalance >= 1) setBalance(Number(tempBalance.toFixed(2)).toString());
    else setBalance(tempBalance.toFixed(2));
  }, [data, account]);

  return (
    <div className="h-screen w-screen bg-(--color-alice-blue) flex items-center justify-center font-tiny5">
      {isLoading ? (
        <LoadingPage />
      ) : petName ? (
        <p className="md:text-3xl sm:text-2xl text-xl">
          {alreadyMinted[index]}
        </p>
      ) : (
        <div className="flex flex-col items-start sm:gap-8 gap-1">
          <p className="md:text-7xl sm:text-5xl text-3xl">TAMAGOTCHI</p>
          <div className="h-max w-max md:p-6 sm:p-4 p-3 sm:border-3 border-2">
            <div className="h-max w-max sm:border-3 border-2 border-dashed md:px-10 md:py-7 px-6 py-4 flex flex-col sm:gap-6 gap-1 items-center font-pressStart">
              <div className="h-max w-full flex items-center justify-between mb md:text-sm xs:text-[8px] text-[6px]">
                <p>{`Game balance: ${balance}`}</p>
                <p>
                  {account.address?.slice(0, 6) +
                    "....." +
                    account.address?.slice(38)}
                </p>
              </div>
              <p className="md:text-2xl sm:text-xl xs:text-base xxs:text-[12px] text-[10px]">
                Adopt your tamagotchi
              </p>

              <form
                onSubmit={handleAdoption}
                className="w-full flex flex-col items-center"
              >
                <input
                  name="name"
                  className="w-full bg-white sm:py-3 sm:px-4 sm:text-base text-[10px] px-2 py-1 rounded-lg"
                  placeholder="Enter a name"
                  required
                />
                <button
                  type="submit"
                  className="mt-3 bg-blue-grey sm:px-5 sm:py-3 px-2 py-1 sm:border-2 border-1 sm:rounded-2xl rounded-md md:text-base sm:text-sm xs:text-xs text-[7px]"
                >
                  Adopt
                </button>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
