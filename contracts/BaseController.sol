// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Hack.sol";
import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./interfaces/IERC20.sol";
import "./StateWriter.sol";
import "./ControllerStateCache.sol";

abstract contract BaseController is Hack, IPlug, ControllerStateCache {
    struct Msg {
        address token;
        uint256 amount;
        address sender;
        uint256 satteliteSlug;
    }

    ISocket public _socket__;
    StateWriter public _stateWritter__;
    Msg internal _msg;

    error NotSocket();
    error NotSattelite();

    constructor(address socket_, address owner_) Hack(owner_) {
        _socket__ = ISocket(socket_);
    }

    modifier onlySatteliteCall {
        if (msg.sender != address(this)) revert NotSattelite();
        _;
    }

    function updateStateWriter(address stateWriter_) external onlyOwner {
        _stateWritter__ = StateWriter(stateWriter_);
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function configureSatellite(
        uint256 satelliteSlug_,
        address satelliteAddress_
    ) external onlyOwner {
        _socket__.setPlugConfig(
            satelliteSlug_,
            satelliteAddress_,
            "FAST"
        );
    }

    function inbound(bytes calldata payload_) external payable {
        if (
            msg.sender != address(_socket__) ||
            msg.sender != owner()
        ) revert NotSocket();

        (
            address token,
            uint256 amount,
            address msgSender,
            uint256 satteliteSlug,
            bytes memory callData
        ) = abi.decode(payload_, (address, uint256, address, uint256, bytes));

        _msg = Msg(
            token,
            amount,
            msgSender,
            satteliteSlug
        );

        (bool success, bytes memory result) = address(this).call(
            callData
        );

        bytes memory payload = abi.encode(_stateUpdates);
        _stateWritter__.writeState(payload);

        delete _stateUpdates;
        delete _msg;
    }
}
