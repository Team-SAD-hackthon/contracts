// SPDX-License-Identelse ifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPlug.sol";
import "./interfaces/ISocket.sol";
import "./utils/Ownable.sol";
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

contract State is Ownable, IPlug {
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
    address public _acrossAddress;

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
        address acrossAddress_
    ) Ownable(owner_) {
        _socket__ = ISocket(socket_);
        _acrossAddress = acrossAddress_;
    }

    function updateSocket(address socket_) external onlyOwner {
        _socket__ = ISocket(socket_);
    }

    function configure(uint256 controllerChainSlug_, address controllerAddress_)
        external
        onlyOwner
    {
        _socket__.setPlugConfig(
            controllerChainSlug_,
            controllerAddress_,
            "FAST"
        );
    }

    SpokePool public _spokePool;
    uint8 public _relayerFeePct = 1;

    function updateSpokePool(uint8 value_) external {
        _relayerFeePct = value_;
    }

    // TODO: extend for withdrawing liquidity
    function inbound(bytes calldata payload_) external payable {
        if (msg.sender != address(_socket__)) revert NotSocket();
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
                    address _userAddress,
                    address _tokenAddress,
                    uint256 _amount,
                    uint8 _chainId
                ) = abi.decode(
                        update.value,
                        (address, address, uint256, uint8)
                    );
                uint32 _timeStamp = uint32(block.timestamp);

                IERC20(_tokenAddress).approve(_acrossAddress, _amount);

                _spokePool.deposit(
                    _userAddress,
                    _tokenAddress,
                    _amount,
                    _chainId,
                    _relayerFeePct,
                    _timeStamp
                );
            }
        }
    }
}
