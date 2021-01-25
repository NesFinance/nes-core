// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/Basic.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IMembers.sol";

contract Controller is Basic {

    using SafeMath for uint256;
    IMasterChef public masterchef;
    IMembers public member;

    constructor(address _masterchef, IMembers _member) public {
        masterchef = IMasterChef(_masterchef);
        member = _member;
    }    

    function mint(address _user, uint256 _amount) onlyMod public {
        masterchef.mintController(_user, _amount);
    }

    function registerMember(address _user, address _ref) public {
        if(member.isMember(_ref) == false){
            _ref = member.membersList(0);
        }
        if(member.isMember(_user) == false){
            member.addMember(_user, _ref);
        }        
    }

}