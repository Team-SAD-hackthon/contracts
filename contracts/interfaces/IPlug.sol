// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(bytes calldata payload_) external payable;
}
