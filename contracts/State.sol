// SPDX-License-Identelse ifier: UNLICENSED
pragma solidity 0.8.17;

import "./Hack.sol";
import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./interfaces/IERC20.sol";

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

contract State is Hack, IPlug {
    enum UpdateType {
        ADDRESS,
        UINT8,
        UINT64,
        UINT256,
        BOOL,
        BYTES,
        BYTES4,
        BYTES32,
        WITHDRAW
    }

    struct StateUpdate {
        UpdateType updateType;
        bytes32 variable;
        bytes value;
    }

    ISocket public _socket__;
    uint256 _stateChainSlug;
    SpokePool public _spokePool;
    uint64 public _relayerFeePct = 1e16;

    mapping(bytes32 => address) _addressMap;
    mapping(bytes32 => uint8) _uint8Map;
    mapping(bytes32 => uint64) _uint64Map;
    mapping(bytes32 => uint256) _uint256Map;
    mapping(bytes32 => bool) _boolMap;
    mapping(bytes32 => bytes) _bytesMap;
    mapping(bytes32 => bytes4) _bytes4Map;
    mapping(bytes32 => bytes32) _bytes32Map;

    error NotSocket();

    constructor(
        address socket_,
        address owner_,
        uint256 stateChainSlug_
    ) Hack(owner_) {
        _socket__ = ISocket(socket_);
        _stateChainSlug = stateChainSlug_;
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function configureStateWriter(uint256 stateWriterChainSlug_, address stateWriterAddress_)
        external
        onlyOwner
    {
        _socket__.setPlugConfig(
            stateWriterChainSlug_,
            stateWriterAddress_,
            "FAST"
        );
    }

    function updateRelayerFeePct(uint64 value_) external {
        _relayerFeePct = value_;
    }

    function inbound(bytes calldata payload_) external payable {
        if (
            msg.sender != address(_socket__) ||
            msg.sender != owner()
        ) revert NotSocket();

        StateUpdate[] memory updates = abi.decode(payload_, (StateUpdate[]));
        uint256 len = updates.length;
        for (uint256 i = 0; i < len; i++) {
            StateUpdate memory update = updates[i];
            if (update.updateType == UpdateType.ADDRESS) {
                address value = abi.decode(update.value, (address));
                _addressMap[update.variable] = value;
            } else if (update.updateType == UpdateType.UINT8) {
                uint8 value = abi.decode(update.value, (uint8));
                _uint8Map[update.variable] = value;
            } else if (update.updateType == UpdateType.UINT64) {
                uint64 value = abi.decode(update.value, (uint64));
                _uint64Map[update.variable] = value;
            } else if (update.updateType == UpdateType.UINT256) {
                uint256 value = abi.decode(update.value, (uint256));
                _uint256Map[update.variable] = value;
            } else if (update.updateType == UpdateType.BOOL) {
                bool value = abi.decode(update.value, (bool));
                _boolMap[update.variable] = value;
            } else if (update.updateType == UpdateType.BYTES) {
                bytes memory value = abi.decode(update.value, (bytes));
                _bytesMap[update.variable] = value;
            } else if (update.updateType == UpdateType.BYTES4) {
                bytes4 value = abi.decode(update.value, (bytes4));
                _bytes4Map[update.variable] = value;
            } else if (update.updateType == UpdateType.BYTES32) {
                bytes32 value = abi.decode(update.value, (bytes32));
                _bytes32Map[update.variable] = value;
            } else if (update.updateType == UpdateType.WITHDRAW) {
                (
                    address userAddress,
                    address tokenAddress,
                    uint256 amount,
                    uint256 chainId
                ) = abi.decode(
                    update.value,
                    (address, address, uint256, uint256)
                );
                handleWithdraw(userAddress, tokenAddress, amount, chainId);
            }
        }
    }

    function handleWithdraw(
        address userAddress_,
        address tokenAddress_,
        uint256 amount_,
        uint256 chainId_
    ) private {
        IERC20 token__ = IERC20(tokenAddress_);
        if (chainId_ != _stateChainSlug) {
            uint32 _timeStamp = uint32(block.timestamp);

            token__.approve(address(_spokePool), amount_);

            _spokePool.deposit(
                userAddress_,
                tokenAddress_,
                amount_,
                chainId_,
                _relayerFeePct,
                _timeStamp
            );
        } else {
            token__.transfer(userAddress_, amount_);
        }
    }
}
