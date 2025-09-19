export default function InstructionPage() {
  return (
    <div className="h-screen w-screen bg-alice-blue flex items-center justify-center font-tiny5">
      <div className="h-max w-max max-w-[90%] md:p-6 sm:p-4 p-3 sm:border-3 border-2">
        <div className="h-max w-max max-w-full sm:border-3 border-2 border-dashed md:px-10 md:py-7 sm:px-6 sm:py-4 px-3 py-2 flex flex-col sm:gap-6 gap-4 items-start">
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
      <p className="lg:text-3xl md:text-2xl sm:text-xl xs:text-lg">
        GAME FEATURES
      </p>
      <ul className="list-inside lg:text-2xl md:text-xl sm:text-lg xs:text-sm text-xs">
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
      <p className="lg:text-3xl md:text-2xl sm:text-xl xs:text-lg">
        HOW TO PLAY
      </p>
      <ul className="list-inside lg:text-2xl md:text-xl sm:text-lg xs:text-sm text-xs">
        <li>Give your pet a cute name</li>
        <li>Watch its stats and keep it healthy</li>
        <li>Feed, play, cuddle, bathe and put it to sleep when needed</li>
        <li>Let it grow thourgh different life stages</li>
        <li>Keep it alive as long as possible through consistent care</li>
      </ul>
    </div>
  );
}
