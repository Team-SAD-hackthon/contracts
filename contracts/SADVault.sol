// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./BaseController.sol";

contract SADVault is BaseController {
    bytes32 public constant DEPOSIT_COUNT = keccak256("DEPOSIT_COUNT");
    bytes32 public constant DEPOSITOR_1 = keccak256("DEPOSITOR_1");
    bytes32 public constant DEPOSITOR_2 = keccak256("DEPOSITOR_2");
    bytes32 public constant DEPOSITOR_3 = keccak256("DEPOSITOR_3");
    bytes32 public constant DEPOSIT_AMOUNT = keccak256("DEPOSIT_AMOUNT");
    constructor(address socket_, address owner_)
    BaseController(socket_, owner_) {}

    function deposit() external onlySatteliteCall {
        uint256 depositAmount = getUint256(DEPOSIT_AMOUNT);
        depositAmount = depositAmount + _msg.amount;

        setUint256(
            DEPOSIT_AMOUNT,
            depositAmount
        );

        uint8 depositCount = getUint8(DEPOSIT_COUNT);

        if (depositCount == 0) {
            setAddress(DEPOSITOR_1, _msg.sender);
        } else if (depositCount == 1) {
            setAddress(DEPOSITOR_2, _msg.sender);
        } else if (depositCount == 2) {
            setAddress(DEPOSITOR_3, _msg.sender);
        }
    }
}
