// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPresale {
    function liquidityLocked() external view returns(bool);
}