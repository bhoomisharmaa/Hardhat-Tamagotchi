export default function LoadingPage() {
  return (
    <div className="h-screen w-screen bg-alice-blue flex items-center justify-center font-tiny5">
      <div className="h-max w-max flex flex-col items-center gap-6">
        <p className="h-max w-max text-5xl">LOADING</p>
        <div className="w-80 h-7  animate-loading" />
      </div>
    </div>
  );
}
