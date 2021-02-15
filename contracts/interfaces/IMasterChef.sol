// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {

    function mint(address _user, uint256 _amount) external;

    function tokenLP() external view returns (address);

    function router() external view returns (address);

    function devaddr() external view returns (address);

}