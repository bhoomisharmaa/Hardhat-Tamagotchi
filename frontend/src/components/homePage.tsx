import HeartSvg from "../utils/heartSvg";
import { CustomConnectButton } from "../utils/customConnectButton";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAccount } from "wagmi";

export default function HomePage({
  petName,
  setIsLoading,
}: {
  petName: string;
  setIsLoading: (loading: boolean) => void;
}) {
  const [showHowToPlay, setShowHowToPlay] = useState(false);
  const { isConnected } = useAccount();
  const navigate = useNavigate();
  return (
    <div className="h-screen w-screen bg-(--color-alice-blue) cursor-(--pixel-cursor)">
      <div className="h-full w-full flex items-center justify-center font-tiny5">
        <div className="absolute h-max w-max self-start left-0 m-4">
          <CustomConnectButton text="CONNECT WALLET" />
        </div>
        <div className="flex flex-col items-center">
          <p className="md:text-9xl sm:text-8xl xs:text-7xl xxs:text-6xl text-5xl">
            TAMAGOTCHI
          </p>
          <div className="flex items-center gap-2">
            <HeartSvg />
            <p className="sm:text-4xl xs:text-3xl text-xl">ON CHAIN</p>
            <HeartSvg />
          </div>
          <div className="h-max w-max absolute bottom-0 right-0 m-4 flex items-center gap-2">
            {isConnected ? (
              <button
                onClick={() => {
                  setIsLoading(true);
                  setTimeout(() => {
                    navigate(petName ? "/pet" : "/name");
                  }, 800);
                }}
                className="sm:text-2xl border-2 px-4 py-1.5 rounded-xl"
              >
                START PLAYING
              </button>
            ) : (
              <CustomConnectButton text="START PLAYING" />
            )}
            <button
              onClick={() => navigate("/instructions")}
              className="sm:text-3xl text-xl border-2 px-3 py-1 rounded-xl"
            >
              ?
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
