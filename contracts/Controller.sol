// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/Basic.sol";
import "./interfaces/IMasterChef.sol";

contract Controller is Basic {

    using SafeMath for uint256;
    IMasterChef public masterchef;

    constructor(address _masterchef) public {
        masterchef = IMasterChef(_masterchef);
    }    

    function mint(address _user, uint256 _amount) onlyMod public {
        masterchef.mintController(_user, _amount);
    } 

}