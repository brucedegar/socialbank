// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SocialBankUSDC} from "./SocialBankToken.sol";
import {USDC} from "./USDC.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

/*
 * @title SocialBankEngine
 * @author Bruce
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1 USDC peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * Our SocialBankToken sytem should always be "overcollateralized". At no point, shoudl the value of all
 * collateral <= the $ back value of all the SocialBankToken
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming SocialBankToken, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS (DAI) system
 */

contract SocialBankEngine is ReentrancyGuard {
    /**
     * ERRORS
     */
    error SocialBankEngine_NeedMoreThanZero();
    error SocialBankEngine_NotAllowedToken();
    error SocialBankEngine_TokenAndPriceAddressesShouldHaveSameLength();
    error SocialBankEngine_TransferFailed();
    error SocialBankEngine_HealthFactorIsBreakHealthFactor(
        uint256 healthFactor
    );
    error SocialBankEngine_MintFailed();
    error SocialBankEngine_HealthFactorOk();
    error SocialBankEngine_HealthFactorNotImproved();

    /***********
     *** TYPES ***
     ***********/

    /**
     * STATE VARIABLE
     */

    mapping(address user => uint256 amount) private s_collateralDeposited;

    // This keep the number of SocialBankUSD hold by each user
    mapping(address user => uint256 amountSbuMinted) private s_sbuMinted;

    // Because we can't loop through the map that why we need to
    // create a separate list to store collateral tokens
    address private s_collateralToken;
    USDC private immutable usdcToken;
    SocialBankUSDC private immutable i_sbu;

    /**
     * EVENTS
     */
    event CollateralDeposited(
        address indexed sender,
        uint256 indexed amountCollateral
    );

    event CollateralRedeemed(
        address indexed redeemFrom,
        address indexed redeemTo,
        uint256 amount
    );

    /**
     * MODIFIERS
     */
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert SocialBankEngine_NeedMoreThanZero();
        }
        _;
    }

    // create a new modifier that allow a certain of address token
    modifier isAllowedToken(address tokenAddress) {
        if (tokenAddress != s_collateralToken) {
            revert SocialBankEngine_NotAllowedToken();
        }
        _;
    }

    /**
     * FUNCTIONS
     */
    constructor(address tokenAddress, address sbuAddress) {
        s_collateralToken = tokenAddress;
        // This function will call the Ownable function
        // constructor(address initialOwner) {
        i_sbu = SocialBankUSDC(sbuAddress);
        usdcToken = USDC(s_collateralToken);
    }

    /**
     * External FUNCTIONS
     */
    // This function will put collateral and create new stable coin
    function depositCollateralAndMintSbu(uint256 amount) public {
        depositCollateral(amount);
        mintSbu(amount);
    }

    function approveContract(
        address socialBankContract,
        uint256 amount
    ) public {
        usdcToken.approve(socialBankContract, amount);
    }

    function getUSDCBalance(address accountAddress) public view returns (uint) {
        return usdcToken.balanceOf(accountAddress);
    }

    function getSBUBalance(address accountAddress) public view returns (uint) {
        return i_sbu.balanceOf(accountAddress);
    }

    /**
     *
     * @param amountCollateral - the amount of collateral to deposit
     */
    function depositCollateral(
        uint256 amountCollateral
    )
        public
        moreThanZero(amountCollateral)
        nonReentrant // This assure that reentrant attack when working with web3 - https://solidity-by-example.org/hacks/re-entrancy/
    {
        s_collateralDeposited[msg.sender] += amountCollateral;
        // Send USDC to the contract
        bool success = usdcToken.transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );

        if (!success) {
            revert SocialBankEngine_TransferFailed();
        }
    }

    /**
     * In order to allow redeem collater:
     * 1. The health factor must be over than 1 AFTER collteral pulled out
     *
     */
    function redeemCollateral(
        uint256 amountCollateralRedeem
    ) public moreThanZero(amountCollateralRedeem) nonReentrant {
        _redeemCollateral(amountCollateralRedeem, msg.sender, msg.sender);
    }

    // Check if the collateral value >= minimum threshold
    function mintSbu(
        uint256 amountSbuToMint
    ) public moreThanZero(amountSbuToMint) nonReentrant {
        s_sbuMinted[msg.sender] += amountSbuToMint;

        // Mint SocialBankToken
        bool minted = i_sbu.mint(msg.sender, amountSbuToMint);
        if (!minted) {
            revert SocialBankEngine_MintFailed();
        }
    }

    // This function will exchange stablecoin back to collateral (USDC)
    function redeemCollateralForSbu(
        uint256 amount
    ) public moreThanZero(amount) {
        // burn SocialBankToken first

        burnSbu(amount);
        // the get back collateral
        // need to convert SocialBankToken to collateral?
        redeemCollateral(amount);
    }

    // For the case they worried that there are too much stabe coin then they want to reduce
    // the number of coins
    function burnSbu(uint256 amount) public moreThanZero(amount) {
        // There is a need to check whether the amount is bigger than avaialbe amount?
        _burnSbu(amount, msg.sender, msg.sender);
    }

    /**
     * PRIVATE AND INTERNAL View Functions
     */

    function _redeemCollateral(
        uint256 amountCollateral,
        address from,
        address to
    ) private {
        s_collateralDeposited[from] -= amountCollateral;
        bool success = usdcToken.transfer(to, amountCollateral);

        if (!success) {
            revert SocialBankEngine_TransferFailed();
        }
    }

    function _burnSbu(
        uint256 amount,
        address onBehalfOf,
        address sbuFromAddress
    ) private {
        s_sbuMinted[onBehalfOf] -= amount;

        bool success = i_sbu.transferFrom(
            sbuFromAddress,
            address(this),
            amount
        );
        if (!success) {
            revert SocialBankEngine_TransferFailed();
        }
        i_sbu.burn(amount);
    }

    function _getAccountInformation(
        address user
    ) private view returns (uint256) {
        uint256 totalSbuMinted = s_sbuMinted[user];
        return (totalSbuMinted);
    }

    /**
     * PUBLIC & External View Functions
     */

    function getAccountInformation(
        address user
    ) external view returns (uint256 totalSbuMinted) {
        return _getAccountInformation(user);
    }

    function getTotalCollateralForTokenAndUser(
        address user
    ) external view returns (uint256 totalCollateralForTokenAndUser) {
        return s_collateralDeposited[user];
    }

    function getTokenAddress() external view returns (address) {
        return s_collateralToken;
    }

    function getCollateralBalanceOfUser(
        address user
    ) external view returns (uint256) {
        return s_collateralDeposited[user];
    }
}
