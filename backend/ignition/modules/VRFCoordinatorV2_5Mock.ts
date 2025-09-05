import { buildModule } from "@nomicfoundation/ignition-core";

export default buildModule("Tamagotchi", (m) => {
  const BASE_FEE = "250000000000000000";
  const GAS_PRICE_LINK = 1e9;
  const vrfCoordinatorV2_5Mock = m.contract("VRFCoordinatorV2_5Mock", [
    BASE_FEE,
    GAS_PRICE_LINK,
  ]);
  return { vrfCoordinatorV2_5Mock };
});
