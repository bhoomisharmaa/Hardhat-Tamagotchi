// SPDX-License-Identifier: MIT
// A mock for testing code that relies on VRFCoordinatorV2_5.
pragma solidity ^0.8.19;
import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract MyVRFCoordinatorV2_5Mock is VRFCoordinatorV2_5Mock {
    constructor(
        uint96 baseFee,
        uint96 gasPriceLink,
        int256 wei_per_unit_link
    ) VRFCoordinatorV2_5Mock(baseFee, gasPriceLink, wei_per_unit_link) {}
}
