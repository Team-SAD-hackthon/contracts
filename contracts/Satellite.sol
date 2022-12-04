// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";

interface SpokePool {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
}

// TODO: use safeTransferFrom and safeIncreaseAllowance
contract Satellite is Ownable, IPlug {
    ISocket public _socket__;
    SpokePool public _spokePool;
    uint256 public _controllerChainSlug;
    uint256 public _satelliteSlug;
    uint256 public _stateChainSlug;
    address public _stateAddress;
    uint32 _timeStamp = uint32(block.timestamp);
    uint8 public _relayerFeePct = 1;

    error NoInbound();

    constructor(
        address socket_,
        address owner_,
        uint256 satelliteSlug_
    ) Ownable(owner_) {
        _socket__ = ISocket(socket_);
        _satelliteSlug = satelliteSlug_;
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function updateRelayerFeePct(uint8 value_) external {
        _relayerFeePct = value_;
    }

    function updateSatelliteSlug(uint256 satelliteSlug_) external onlyOwner {
        _satelliteSlug = satelliteSlug_;
    }

    function configureState(uint256 stateChainSlug_, address stateAddress_)
        external
    {
        _stateChainSlug = stateChainSlug_;
        _stateAddress = stateAddress_;
    }

    function configureController(
        uint256 controllerChainSlug_,
        address controllerAddress_
    ) external onlyOwner {
        _controllerChainSlug = controllerChainSlug_;
        _socket__.setPlugConfig(
            controllerChainSlug_,
            controllerAddress_,
            "FAST"
        );
    }

    function callController(
        uint256 controllerGasLimit_,
        bytes calldata controllerCalldata_
    ) external {
        bytes memory payload = abi.encode(
            address(0x0), // token address
            uint256(0x0), // token amount
            msg.sender,
            _satelliteSlug,
            controllerCalldata_
        );
        _socket__.outbound(_controllerChainSlug, controllerGasLimit_, payload);
    }

    function callControllerWithTokens(
        uint256 controllerGasLimit_,
        address token_,
        uint256 amount_,
        bytes calldata controllerCalldata_
    ) external {
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);
        IERC20(token_).approve(address(_spokePool), amount_);
        _spokePool.deposit(
            _stateAddress,
            token_,
            amount_,
            _stateChainSlug,
            _relayerFeePct,
            _timeStamp
        );

        uint256 _finalAmount = amount_ - (amount_ * (_relayerFeePct / 100));

        bytes memory payload = abi.encode(
            token_,
            _finalAmount,
            msg.sender,
            _satelliteSlug,
            controllerCalldata_
        );
        _socket__.outbound(_controllerChainSlug, controllerGasLimit_, payload);
    }

    function inbound(bytes calldata) external payable {
        revert NoInbound();
    }
}
