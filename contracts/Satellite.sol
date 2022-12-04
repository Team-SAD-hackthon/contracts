// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";

// TODO: use safeTransferFrom and safeIncreaseAllowance
contract Satellite is Ownable, IPlug {
    ISocket public _socket__;
    address public _controllerAddress;
    uint256 public _controllerChainSlug;

    constructor(address socket_, address owner_) Ownable(_owner) {
        _socket__ = ISocket(socket_);
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function configure(
        uint256 controllerChainSlug_,
        address controllerAddress_
    ) external onlyOwner {
        _controllerAddress = controllerAddress_;
        _controllerChainSlug = controllerChainSlug_;

        _socket__.setPlugConfig(
            controllerChainSlug_,
            controllerAddress_,
            "FAST"
        );
    }

    function callController(uint256 controllerGasLimit_, bytes calldata controllerCalldata_) external {
        bytes memory payload = abi.encode(
            address(0x0), // token address
            uint256(0x0), // token amount
            msg.sender,
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
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        // IERC20(asset).approve(across, amount);
        // TODO: deposit to across

        bytes memory payload = abi.encode(
            token_,
            amount_,
            msg.sender,
            controllerCalldata_
        );
        _socket__.outbound(_controllerChainSlug, controllerGasLimit_, payload);

    }
}
