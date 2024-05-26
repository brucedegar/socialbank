// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeploySocialBank} from "../script/DeploySocialBank.s.sol";
import {SocialBankUSDC} from "../src/SocialBankToken.sol";
import {SocialBankEngine} from "../src/SocialBankEngine.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract SocialBankEngineTest is Test {
    event CollateralRedeemed(
        address indexed redeemFrom,
        address indexed redeemTo,
        uint256 amount
    );
    DeploySocialBank deployer;
    SocialBankUSDC sbu;
    SocialBankEngine public engine;
    HelperConfig helperConfig;

    address usdc;

    address public USER = address(1);
    uint256 public constant AMOUNT_COLLATERAL = 10;
    uint256 public constant STARTING_ERC20_BALANCE = 10;
    uint256 public constant AMOUNT_TO_MINT = 10;
    uint256 public constant AMOUNT_TO_MINT_BROKEN = 19000;

    uint256 amountCollateral = 10;
    uint256 amountToMint = 10;

    function setUp() external {
        deployer = new DeploySocialBank();
        (sbu, engine, helperConfig) = deployer.run();

        (usdc, ) = helperConfig.activeNetworkConfig();

        // Mint 10 ether for current user
        ERC20Mock(usdc).mint(USER, STARTING_ERC20_BALANCE);
    }

    // Constructor Tests

    address[] public tokens;

    function testRevertDepositAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(
            SocialBankEngine.SocialBankEngine_NeedMoreThanZero.selector
        );
        engine.depositCollateral(0);
        vm.stopPrank();
    }

    modifier depositeCollateral() {
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testDepositCollateralAndMintSbu() public {
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintSbu(AMOUNT_COLLATERAL);
        vm.stopPrank();

        uint256 totalSbuMinted = engine.getAccountInformation(USER);

        console.log("totalSbuMinted: ", totalSbuMinted);
        assert(totalSbuMinted == AMOUNT_TO_MINT);
    }

    modifier depositedCollateralAndMintedToken() {
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), amountCollateral); // amountCollateral = 10
        engine.depositCollateralAndMintSbu(
            amountToMint // amountToMint = 10
        );
        vm.stopPrank();
        _;
    }

    // This function mainly tests the minting of SocialBankToken
    // the numner of SocialBankToken minted should be transferred to the user balance
    function testCanMintWithDepositedCollateral()
        public
        depositedCollateralAndMintedToken
    {
        uint256 userBalance = sbu.balanceOf(USER);
        console.log("userBalance: ", userBalance); // 10
        assert(userBalance == amountToMint);
    }

    function testCanRedeemCollateral() public {
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), amountCollateral); // amountCollateral = 10 ether
        engine.depositCollateralAndMintSbu(
            amountToMint // amountToMint = 10
        );

        uint256 startingBalance = ERC20Mock(usdc).balanceOf(USER);
        console.log("startingBalance: ", startingBalance);

        //console.log("amountCollateral: ", amountCollateral); // 10
        engine.redeemCollateral(10); // amountCollateral = 10

        uint256 endingBalance = ERC20Mock(usdc).balanceOf(USER);
        vm.stopPrank();
        console.log("endingBalance: ", endingBalance); // 0
        assert(endingBalance == 10);
    }

    function testRevertsIfRedeemAmountIsZero() public {
        // amountCollateral = 10
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), amountCollateral);
        engine.depositCollateralAndMintSbu(
            amountToMint // amountToMint = 10
        );

        vm.expectRevert(
            SocialBankEngine.SocialBankEngine_NeedMoreThanZero.selector
        );
        engine.redeemCollateral(0);
        vm.stopPrank();
    }

    function testEmitCollateralRedeemedWithCorrectArgs()
        public
        depositeCollateral
    {
        // amountCollateral = 10
        vm.expectEmit();
        emit CollateralRedeemed(USER, USER, amountCollateral);
        vm.startPrank(USER);
        engine.redeemCollateral(amountCollateral);
        vm.stopPrank();
    }

    //////////////////////////////////////////////
    // redeemCollateralForSocialBankToken Tests //
    //////////////////////////////////////////////

    function testMustRedeemMoreThanZero()
        public
        depositedCollateralAndMintedToken
    {
        vm.expectRevert(
            SocialBankEngine.SocialBankEngine_NeedMoreThanZero.selector
        );
        engine.redeemCollateralForSbu(0);
    }

    // Expect the amount of SBU after call reedemCollateralForSbu
    function testSBUBurnAmountAfterRedeemCollateralForSbu() public {
        vm.startPrank(USER);
        ERC20Mock(usdc).approve(address(engine), amountCollateral); // allow engine to deposit collateral
        engine.depositCollateralAndMintSbu(amountToMint);

        // remember that to approve the engine to burn SBU
        sbu.approve(address(engine), amountToMint); // allow engine to burn SBU amountToMint

        uint256 startingBalance = sbu.balanceOf(USER);
        console.log("startingBalance: ", startingBalance); // 10

        engine.redeemCollateralForSbu(amountToMint);
        vm.stopPrank();

        uint256 endingBalance = sbu.balanceOf(USER);
        console.log("endingBalance: ", endingBalance); // 0
        assert(endingBalance == 0);
    }
}
