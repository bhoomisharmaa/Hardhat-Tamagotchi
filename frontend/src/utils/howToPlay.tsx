import HeartSvg from "./heartSvg";

export default function HowToPlayAndGameFeatures({
  setShowHowToPlay,
}: {
  setShowHowToPlay: Function;
}) {
  return (
    <div
      onClick={() => setShowHowToPlay(false)}
      className="z-10 absolute left-0 top-0 h-full w-full flex items-center justify-center bg-(--color-blue-grey)"
    >
      <div className="h-max w-max flex flex-col items-start bg-(--color-alice-blue) border-1 rounded-xl overflow-hidden">
        <div className="h-max w-full bg-(--color-boy-blue) border-b-1 p-1">
          <HeartSvg />
        </div>
        <div className="h-max w-max px-6 py-3 mx-3 flex flex-col gap-4">
          <GameFeatures />
          <HowToPlay />
        </div>
      </div>
    </div>
  );
}

function GameFeatures() {
  return (
    <div className="flex flex-col items-start gap-1">
      <p className="text-3xl">GAME FEATURES</p>
      <ul className="list-inside text-2xl">
        <li>Unique on-chain NFT pet</li>
        <li>Grows through life stages</li>
        <li>Dynamic stats like hunger, happiness, energy, and cleanliness</li>
        <li>Care through feeding, playing, bathing, cuddling, and sleeping</li>
      </ul>
    </div>
  );
}

function HowToPlay() {
  return (
    <div className="flex flex-col items-start gap-1">
      <p className="text-3xl">HOW TO PLAY</p>
      <ul className="list-inside text-2xl">
        <li>Give your pet a cute name</li>
        <li>Watch its stats and keep it healthy</li>
        <li>Feed, play, cuddle, bathe and put it to sleep when needed</li>
        <li>Let it grow thourgh different life stages</li>
        <li>Keep it alive as long as possible through consistent care</li>
      </ul>
    </div>
  );
}
