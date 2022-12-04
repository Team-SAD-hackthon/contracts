// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "./interfaces/ISocket.sol";
import "./utils/Ownable.sol";
import "./interfaces/IPlug.sol";

contract StateWriter is Ownable, IPlug {
    ISocket public _socket__;
    uint256 public _stateChainSlug;
    address public _controller;
    uint256 public _gasLimit = 2_000_000;

    error NotController();
    error NoInbound();

    constructor(address socket_, address owner_, address controller_) Ownable(owner_) {
        _socket__ = ISocket(socket_);
        _controller = controller_;
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function updateController(address controller_) external onlyOwner {
        _controller = controller_;
    }

    function updateGasLimit(uint256 gasLimit_) external onlyOwner {
        _gasLimit = gasLimit_;
    }

    function configureState(
        uint256 stateChainSlug_,
        address stateAddress_
    ) external onlyOwner {
        _stateChainSlug = stateChainSlug_;
        _socket__.setPlugConfig(
            stateChainSlug_,
            stateAddress_,
            "FAST"
        );
    }

    function writeState(bytes calldata payload_) external {
        if (msg.sender != _controller) revert NotController();
        _socket__.outbound(_stateChainSlug, _gasLimit, payload_);
    }

    function inbound(bytes calldata) external payable {
        revert NoInbound();
    }
}
