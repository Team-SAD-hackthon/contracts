// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";

// TODO: initiate state write from different contract since plugs can talk to
//      only one contract on remote chain, and we wanna talk to both satellite
//      and state
contract Controller is Ownable, IPlug {
    struct Msg {
        address token;
        uint256 amount;
        address sender;
        uint256 satteliteSlug;
    }

    ISocket public _socket__;
    uint256 public _stateChainSlug;
    Msg internal _msg;

    error NotSocket();
    error NotSattelite();

    constructor(address socket_, address owner_) Ownable(owner_) {
        _socket__ = ISocket(socket_);
    }

    modifier SatteliteCall {
        if (msg.sender != address(this)) revert NotSattelite();
        _;
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
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
        if (msg.sender != address(_socket__)) revert NotSocket();

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

        delete _msg;
    }

    function deposit(address a, uint256 b) external {

    }
}
