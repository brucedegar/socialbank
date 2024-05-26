// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract USDC is ERC20Burnable, Ownable {
    error USDC__MustBeMoreThanZero();
    error USDC__BurnAmountExceedsBalance();
    error USDC__NotZeroAddress();

    constructor() ERC20("USDC", "UDSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert USDC__MustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert USDC__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert USDC__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert USDC__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
