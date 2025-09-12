import HeartSvg from "../utils/heartSvg";
import { CustomConnectButton } from "../utils/customConnectButton";
import HowToPlayAndGameFeatures from "../utils/howToPlay";
import { useState } from "react";

export default function HomePage() {
  const [showHowToPlay, setShowHowToPlay] = useState(false);
  return (
    <div className="h-screen w-screen bg-(--color-alice-blue) cursor-(--pixel-cursor)">
      <div className="h-full w-full flex items-center justify-center font-tiny5">
        <div className="absolute h-max w-max self-start left-0 m-4">
          <CustomConnectButton />
        </div>
        <div className="flex flex-col items-center">
          <p className="text-9xl">TAMAGOTCHI</p>
          <div className="flex items-center gap-2">
            <HeartSvg />
            <p className="text-4xl">ON CHAIN</p>
            <HeartSvg />
          </div>
          <div className="h-max w-max absolute bottom-0 right-0 m-4 flex items-center gap-2">
            <button
              onClick={() => setShowHowToPlay(true)}
              className="text-2xl border-2 px-4 py-1.5 rounded-xl"
            >
              START PLAYING
            </button>
            <button
              onClick={() => setShowHowToPlay(true)}
              className="text-3xl border-2 px-3 py-1 rounded-xl"
            >
              ?
            </button>
          </div>
        </div>
        {showHowToPlay ? (
          <HowToPlayAndGameFeatures setShowHowToPlay={setShowHowToPlay} />
        ) : (
          ""
        )}
      </div>
    </div>
  );
}
