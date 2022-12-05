// SPDX-License-Identifier: UNLICENSED
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

// TODO: use safeTransferFrom and safeIncreaseAllowance
// TODO: no dl/ll needed in case on same chain contracts
contract Satellite is Hack, IPlug {
    ISocket public _socket__;
    SpokePool public _spokePool;
    uint256 public _controllerChainSlug;
    uint256 public _satelliteSlug;
    uint256 public _stateChainSlug;
    address public _stateAddress;
    uint64 public _relayerFeePct = 1e16;

    // TODO: expand for non usdc
    // chainSlug => usdc address
    mapping(uint256 => address) _usdcTokenAddresses;

    error NoInbound();
    error NotUSDC();

    constructor(
        address socket_,
        address owner_,
        uint256 satelliteSlug_
    ) Hack(owner_) {
        _socket__ = ISocket(socket_);
        _satelliteSlug = satelliteSlug_;

        _usdcTokenAddresses[10] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        _usdcTokenAddresses[137] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        _usdcTokenAddresses[42161] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
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

    function updateUSDCAddress(uint256 chainSlug_, address usdc_) external onlyOwner {
        _usdcTokenAddresses[chainSlug_] = usdc_;
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
        _socket__.outbound{value: 0.0001 ether}
            (_controllerChainSlug, controllerGasLimit_, payload);
    }

    function callControllerWithTokens(
        uint256 controllerGasLimit_,
        address token_,
        uint256 amount_,
        bytes calldata controllerCalldata_
    ) external {
        if (token_ != _usdcTokenAddresses[_satelliteSlug]) revert NotUSDC();
        IERC20 token__ = IERC20(token_);
        token__.transferFrom(msg.sender, address(this), amount_);

        uint256 finalAmount;
        if (_stateChainSlug != _satelliteSlug) {
            token__.approve(address(_spokePool), amount_);
            uint32 _timeStamp = uint32(block.timestamp);
            _spokePool.deposit(
                _stateAddress,
                token_,
                amount_,
                _stateChainSlug,
                _relayerFeePct,
                _timeStamp
            );
            finalAmount = (amount_ * (1e18 - _relayerFeePct)) / 1e18;
        } else {
            token__.transfer(_stateAddress, amount_);
            finalAmount = amount_;
        }

        bytes memory payload = abi.encode(
            // send state chain token address for unified accounting
            _usdcTokenAddresses[_stateChainSlug],
            finalAmount,
            msg.sender,
            _satelliteSlug,
            controllerCalldata_
        );
        _socket__.outbound{value: 0.0001 ether}
            (_controllerChainSlug, controllerGasLimit_, payload);
    }

    function inbound(bytes calldata) external payable {
        revert NoInbound();
    }
}
