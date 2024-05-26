// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {SocialBankEngine} from "../src/SocialBankEngine.sol";
import {SocialBankUSDC} from "../src/SocialBankToken.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeploySocialBank is Script {
    function run()
        external
        returns (SocialBankUSDC, SocialBankEngine, HelperConfig)
    {
        HelperConfig helperConfig = new HelperConfig();
        (address usdc, uint256 deployerKey) = helperConfig
            .activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        SocialBankUSDC dsc = new SocialBankUSDC();
        // we need to pass a list of token addresses and price feed addresses

        SocialBankEngine engine = new SocialBankEngine(usdc, address(dsc));

        // Transfer the ownership to engine
        dsc.transferOwnership(address(engine));

        vm.stopBroadcast();

        return (dsc, engine, helperConfig);
    }
}
