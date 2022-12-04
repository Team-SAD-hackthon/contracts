// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./utils/Ownable.sol";

contract State is Ownable, IPlug {

    enum UpdateType {
        ADDRESS,
        UINT8,
        UINT64,
        UINT256,
        BOOL,
        BYTES,
        BYTES4,
        BYTES32
    }

    struct StateUpdate {
        UpdateType updateType;
        bytes32 variable;
        bytes value;
    }

    ISocket public _socket__;

    mapping(bytes32 => address) _addressMap;
    mapping(bytes32 => uint8) _uint8Map;
    mapping(bytes32 => uint64) _uint64Map;
    mapping(bytes32 => uint256) _uint256Map;
    mapping(bytes32 => bool) _boolMap;
    mapping(bytes32 => bytes) _bytesMap;
    mapping(bytes32 => bytes4) _bytes4Map;
    mapping(bytes32 => bytes32) _bytes32Map;

    error NotSocket();

    constructor(address socket_, address owner_) Ownable(owner_) {
        _socket__ = ISocket(socket_);
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function configure(
        uint256 controllerChainSlug_,
        address controllerAddress_
    ) external onlyOwner {
        _socket__.setPlugConfig(
            controllerChainSlug_,
            controllerAddress_,
            "FAST"
        );
    }

    // TODO: extend for withdrawing liquidity
    function inbound(bytes calldata payload_) external payable {
        if (msg.sender != address(_socket__)) revert NotSocket();
        (StateUpdate[] memory updates) = abi.decode(payload_, (StateUpdate[]));
        uint256 len = updates.length;
        for (uint256 i = 0; i < len; i++) {
            StateUpdate memory update = updates[i];
            if (update.updateType == UpdateType.ADDRESS) {
                (address value) = abi.decode(update.value, (address));
                _addressMap[update.variable] = value;
            }
            // TODO: replicate for other types
        }
    }
}
