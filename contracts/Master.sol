// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";

interface IAave {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);
}

contract Master {
    IAave aave;

    // user => token => amount
    mapping(address => mapping( address => uint256)) suppliedAmount;
    // user => token => amount
    mapping(address => mapping( address => uint256)) borrowedAmount;

    constructor(address _aave) {
        aave = IAave(_aave);
    }

    function supply(
        address asset,
        uint256 amount
    ) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        suppliedAmount[msg.sender][asset] += amount;
        IERC20(asset).approve(address(aave), amount);
        aave.supply(asset, amount, address(this), 0);
    }

    function withdraw(
        address asset,
        uint256 amount
    ) external {
        suppliedAmount[msg.sender][asset] -= amount;
        aave.withdraw(asset, amount, msg.sender);
    }

    function borrow(
        address asset,
        uint256 amount
    ) external {
        borrowedAmount[msg.sender][asset] += amount;
        aave.borrow(asset, amount, 1, 0, msg.sender);
    }

    function repay(
        address asset,
        uint256 amount
    ) external {
        borrowedAmount[msg.sender][asset] -= amount;
        aave.repay(asset, amount, 1, address(this));
    }

    function rescue(address asset, uint256 amount) external {
        IERC20(asset).transfer(msg.sender, amount);
    }
}
