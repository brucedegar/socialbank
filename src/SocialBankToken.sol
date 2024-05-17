// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title SocialBankUSDC
 * @author Bruce
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USDC)
 * Collateral Type: USDC
 *
 * This is the contract meant to be owned by DSCEngine.
 * It is a ERC20 token that can be minted and burned by the DSCEngine smart contract.
 */

contract SocialBankUSDC is ERC20Burnable, Ownable {
    error SocialBankUSDC__MustBeMoreThanZero();
    error SocialBankUSDC__BurnAmountExceedsBalance();
    error SocialBankUSDC__NotZeroAddress();

    constructor() ERC20("SocialBankUSDC", "socUDSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert SocialBankUSDC__MustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert SocialBankUSDC__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert SocialBankUSDC__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert SocialBankUSDC__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
