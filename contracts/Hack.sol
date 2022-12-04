// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";

contract Hack is Ownable {
    constructor(address owner_) Ownable(owner_) {}

    function rescueERC20(
        address receiver_,
        address token_,
        uint256 amount_
    ) external onlyOwner {
        IERC20(token_).transfer(receiver_, amount_);
    }

    function rescueEther(
        address payable receiver_,
        uint256 amount_
    ) external onlyOwner {
        receiver_.transfer(amount_);
    }
}
