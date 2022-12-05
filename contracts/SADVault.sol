// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./BaseController.sol";

contract SADVault is BaseController {
    bytes32 public constant DEPOSIT_COUNT = keccak256("DEPOSIT_COUNT");
    bytes32 public constant DEPOSIT_AMOUNT = keccak256("DEPOSIT_AMOUNT");
    bytes32 public constant DEPOSIT_TOKEN = keccak256("DEPOSIT_TOKEN");

    bytes32 public constant DEPOSITOR_1_ADDRESS = keccak256("DEPOSITOR_1_ADDRESS");
    bytes32 public constant DEPOSITOR_1_CHAIN = keccak256("DEPOSITOR_1_CHAIN");

    bytes32 public constant DEPOSITOR_2_ADDRESS = keccak256("DEPOSITOR_2_ADDRESS");
    bytes32 public constant DEPOSITOR_2_CHAIN = keccak256("DEPOSITOR_2_CHAIN");

    bytes32 public constant DEPOSITOR_3_ADDRESS = keccak256("DEPOSITOR_3_ADDRESS");
    bytes32 public constant DEPOSITOR_3_CHAIN = keccak256("DEPOSITOR_3_CHAIN");

    // TODO: expand for non usdc
    // chainSlug => usdc address
    mapping(uint256 => address) _usdcTokenAddresses;

    constructor(address socket_, address owner_)
    BaseController(socket_, owner_) {
        _usdcTokenAddresses[10] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        _usdcTokenAddresses[137] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        _usdcTokenAddresses[42161] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    }

    function deposit() external onlySatelliteCall {
        uint256 depositAmount = getUint256(DEPOSIT_AMOUNT);
        depositAmount = depositAmount + _msg.amount;

        setUint256(
            DEPOSIT_AMOUNT,
            depositAmount
        );
        setAddress(
            DEPOSIT_TOKEN,
            _msg.token
        );

        uint8 depositCount = getUint8(DEPOSIT_COUNT);

        if (depositCount == 0) {
            setAddress(DEPOSITOR_1_ADDRESS, _msg.sender);
            setUint256(DEPOSITOR_1_CHAIN, _msg.satelliteSlug);
        } else if (depositCount == 1) {
            setAddress(DEPOSITOR_2_ADDRESS, _msg.sender);
            setUint256(DEPOSITOR_2_CHAIN, _msg.satelliteSlug);
        } else if (depositCount == 2) {
            setAddress(DEPOSITOR_3_ADDRESS, _msg.sender);
            setUint256(DEPOSITOR_3_CHAIN, _msg.satelliteSlug);
        }
    }

    function selectWinner() external onlySatelliteCall {
        uint256 winner = block.timestamp % 3;
        if (winner == 0) {
            withdraw(
                getAddress(DEPOSITOR_1_ADDRESS),
                getAddress(DEPOSIT_TOKEN),
                getUint256(DEPOSIT_AMOUNT) / 2,
                getUint256(DEPOSITOR_1_CHAIN)
            );
        } else if (winner == 1) {
            withdraw(
                getAddress(DEPOSITOR_2_ADDRESS),
                getAddress(DEPOSIT_TOKEN),
                getUint256(DEPOSIT_AMOUNT) / 2,
                getUint256(DEPOSITOR_2_CHAIN)
            );
        } else if (winner == 2) {
            withdraw(
                getAddress(DEPOSITOR_3_ADDRESS),
                getAddress(DEPOSIT_TOKEN),
                getUint256(DEPOSIT_AMOUNT) / 2,
                getUint256(DEPOSITOR_3_CHAIN)
            );
        }
    }
}
