// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// The IERC20.sol file defines the interface for the ERC20 token standard, which includes the required and
// optional functions that an ERC20 token must implement. The OpenZeppelin ERC20 contract implements this interface,
// which allows it to be recognized as an ERC20 token by other contracts and applications.

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SocialBankUSDC} from "./SocialBankToken.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Test, console} from "forge-std/Test.sol";

/*
 * @title DSCEngine
 * @author Bruce
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1 USDC peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * Our DSC sytem should always be "overcollateralized". At no point, shoudl the value of all
 * collateral <= the $ back value of all the DSC
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS (DAI) system
 */

contract DSCEngine is ReentrancyGuard {
    /**
     * ERRORS
     */
    error DSCEngine_NeedMoreThanZero();
    error DSCEngine_NotAllowedToken();
    error DSCEngine_TokenAndPriceAddressesShouldHaveSameLength();
    error DSCEngine_TransferFailed();
    error DSCEngine_HealthFactorIsBreakHealthFactor(uint256 healthFactor);
    error DSCEngine_MintFailed();
    error DSCEngine_HealthFactorOk();
    error DSCEngine_HealthFactorNotImproved();

    /***********
     *** TYPES ***
     ***********/

    /**
     * STATE VARIABLE
     */
}
