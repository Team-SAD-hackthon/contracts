// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract ControllerStateCache {
    mapping(bytes32 => address) _addressMap;
    mapping(bytes32 => uint8) _uint8Map;
    mapping(bytes32 => uint64) _uint64Map;
    mapping(bytes32 => uint256) _uint256Map;
    mapping(bytes32 => bool) _boolMap;
    mapping(bytes32 => bytes) _bytesMap;
    mapping(bytes32 => bytes4) _bytes4Map;
    mapping(bytes32 => bytes32) _bytes32Map;

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

    StateUpdate[] _stateUpdates;

    function getAddress(bytes32 variable) public view returns (address) {
        return _addressMap[variable];
    }

    function setAddress(bytes32 variable, address value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.ADDRESS,
                variable,
                abi.encode(value)
            )
        );
        _addressMap[variable] = value;
    }

    function getUint8(bytes32 variable) public view returns (uint8) {
        return _uint8Map[variable];
    }

    function setUint8(bytes32 variable, uint8 value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.UINT8,
                variable,
                abi.encode(value)
            )
        );
        _uint8Map[variable] = value;
    }

    function getUint64(bytes32 variable) public view returns (uint64) {
        return _uint64Map[variable];
    }

    function setUint64(bytes32 variable, uint64 value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.UINT64,
                variable,
                abi.encode(value)
            )
        );
        _uint64Map[variable] = value;
    }

    function getUint256(bytes32 variable) public view returns (uint256) {
        return _uint256Map[variable];
    }

    function setUint256(bytes32 variable, uint256 value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.UINT256,
                variable,
                abi.encode(value)
            )
        );
        _uint256Map[variable] = value;
    }

    function getBool(bytes32 variable) public view returns (bool) {
        return _boolMap[variable];
    }

    function setBool(bytes32 variable, bool value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.BOOL,
                variable,
                abi.encode(value)
            )
        );
        _boolMap[variable] = value;
    }

    function getBytes(bytes32 variable) public view returns (bytes memory) {
        return _bytesMap[variable];
    }

    function setBytes(bytes32 variable, bytes memory value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.BYTES,
                variable,
                abi.encode(value)
            )
        );
        _bytesMap[variable] = value;
    }

    function getBytes4(bytes32 variable) public view returns (bytes4) {
        return _bytes4Map[variable];
    }

    function setBytes4(bytes32 variable, bytes4 value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.BYTES4,
                variable,
                abi.encode(value)
            )
        );
        _bytes4Map[variable] = value;
    }

    function getBytes32(bytes32 variable) public view returns (bytes32) {
        return _bytes32Map[variable];
    }

    function setBytes32(bytes32 variable, bytes32 value) internal {
        _stateUpdates.push(
            StateUpdate(
                UpdateType.BYTES32,
                variable,
                abi.encode(value)
            )
        );
        _bytes32Map[variable] = value;
    }

    function withdraw(
        address receiver_,
        address token_,
        uint256 amount_,
        uint256 chainSlug_
    ) internal {
        bytes memory value = abi.encode(
            receiver_,
            token_,
            amount_,
            chainSlug_
        );

        _stateUpdates.push(
            StateUpdate(
                UpdateType.BYTES32,
                0x0,
                value
            )
        );
    }
}
