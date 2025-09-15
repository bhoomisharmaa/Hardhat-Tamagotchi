import { useEffect, useState } from "react";
import { useAccount, useBalance, useWriteContract } from "wagmi";
import type { Abi, Address } from "viem";
import { waitForTransactionReceipt } from "wagmi/actions";

type ContractConfig = {
  address: Address;
  abi: Abi | readonly unknown[];
};

interface NamePageProps {
  contractConfig?: ContractConfig;
  address?: Address;
  config: any;
  setIsLoading: (loading: boolean) => void;
}

export default function NamePage({
  contractConfig,
  address,
  config,
  setIsLoading,
}: NamePageProps) {
  const [balance, setBalance] = useState("0");

  const account = useAccount();
  const { data } = useBalance({ address: account.address, chainId: 11155111 });
  const { writeContractAsync } = useWriteContract();

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
      const receipt = await waitForTransactionReceipt(config, { hash: txn });
      console.log("Receipt:", receipt);
    } catch (error) {
      console.log(error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    const value = Number(data?.value);
    const decimal = Math.pow(10, Number(data?.decimals));
    const tempBalance = value / decimal;
    setBalance(tempBalance.toFixed(2));
  }, [data, account]);

  return (
    <div className="h-screen w-screen bg-(--color-alice-blue) flex items-center justify-center font-tiny5">
      <div className="flex flex-col items-start sm:gap-2 gap-1">
        <p className="md:text-7xl sm:text-5xl text-3xl">TAMAGOTCHI</p>
        <div className="h-max w-max sm:px-7 sm:py-6 px-4 py-5 sm:border-3 border-2">
          <div className="h-max w-max sm:border-3 border-2 border-dashed sm:px-6 sm:py-4 px-3 py-2 flex flex-col sm:gap-2 gap-1 items-center font-pressStart">
            <div className="h-max w-full flex items-center justify-between mb-4 md:text-sm sm:text-xs xs:text-[10px] text-[7px]">
              <p>{`Game balance: ${balance}`}</p>
              <p>
                {account.address?.slice(0, 6) +
                  "....." +
                  account.address?.slice(38)}
              </p>
            </div>
            <p className="md:text-2xl sm:text-xl xs:text-base text-[10px]">
              Create your tamagotchi
            </p>
            <p className="md:text-base sm:text-sm xs:text-xs text-[8px]">
              Name
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
    </div>
  );
}
