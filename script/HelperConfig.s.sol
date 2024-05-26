// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {SocialBankEngine} from "../src/SocialBankEngine.sol";
import {SocialBankUSDC} from "../src/SocialBankToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address usdc;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getPolygonSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateEthAnvilConfig();
        }
    }

    function getPolygonSepoliaConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, // USDC Address on Polygon
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getOrCreateEthAnvilConfig() public returns (NetworkConfig memory) {
        // Check if active config is set?
        if (activeNetworkConfig.usdc != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        ERC20Mock usdcMock = new ERC20Mock();
        vm.stopBroadcast();

        return
            NetworkConfig({
                usdc: address(usdcMock),
                deployerKey: DEFAULT_ANVIL_KEY
            });
    }
}
