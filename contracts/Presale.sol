// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMembers.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWBNB.sol";
import "./libraries/Basic.sol";

contract Presale is Basic {
    using SafeMath for uint256;

    IERC20 public token;
    IMembers public member;
    IMasterChef public masterchef;

    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IWBNB public WBNB = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    // *** Config ***

    uint256 public ROUND_1_CAP_MAX = 10 ether;                  // Maximum amount of BNB to buy in stage 1
    uint256 public ROUND_1_CAP_MIN = 1 ether;                   // Minimum amount of BNB to buy in stage 1
    uint256 public ROUND_2_CAP_MAX = 15 ether;                  // Maximum amount of BNB to buy in stage 2
    uint256 public ROUND_2_CAP_MIN = 1 ether;                   // Minimum amount of BNB to buy in stage 2

    uint256 public HARDCAP = 800 ether;                         // BNB to raise for the presale
    uint256 public HARDCAP_ROUND_1 = 500 ether;                 // BNB from stage 1 to be raised
    uint256 public HARDCAP_ROUND_2 = 300 ether;                 // BNB from stage 2 to be raised

    uint256 public TOKENS = 40000 ether;                        // Tokens to sell
    uint256 public TOKENS_ROUND_1 = 25000 ether;                // Tokens to sell in stage 1
    uint256 public TOKENS_ROUND_2 = 15000 ether;                // Tokens to sell in stage 2
    uint256 public TOKENS_SPONSORS = 2400 ether;                // Tokens for referrals

    uint256 public TOKEN_PER_BNB = 50;                          // 1 BNB = 50 Tokens
    uint256[3] public refPercent = [3, 2, 1];                   // Referral percentages

    uint256 public ROUND_1_START_TIME = now + 5 days;           // Start date of stage 1
    uint256 public ROUND_1_END_TIME = now + 8 days;             // End date of stage 1
    uint256 public ROUND_2_START_TIME = now + 8 days;           // Start date of stage 2
    uint256 public ROUND_2_END_TIME = now + 11 days;            // End date of stage 2
    
    mapping(address => uint256) public whitelistCapsRound_1;    // Round 1 whitelist
    mapping(address => uint256) public whitelistCapsRound_2;    // Round 2 whitelist
    mapping(address => uint256) public contributions_1;         // Contributions Round 1
    mapping(address => uint256) public contributions_2;         // Contributions Round 2

    bool public liquidityLocked;                                // Blocked funds flag

    // --- Config ---

    constructor(address _token, address _member, address _masterchef) public {
        token = IERC20(_token);
        member = IMembers(_member);
        masterchef = IMasterChef(_masterchef);
    }

    function register(address _ref) external {
        require(ROUND_1_START_TIME > now, "Pre registration ended");
        require(member.isMember(msg.sender) == false, "You are already registered");
        if(member.isMember(_ref) == false){
            _ref = member.membersList(0);
        }
        member.addMember(msg.sender, _ref);
        whitelistCapsRound_1[msg.sender] = ROUND_1_CAP_MAX;
        whitelistCapsRound_2[msg.sender] = ROUND_2_CAP_MAX;
    }

    receive() external payable {
        require(now >= ROUND_1_START_TIME, "You can't buy Token");
        require(msg.value > 0, "The value must be greater than zero.");
        require(HARDCAP > 0, "The total of BNB was collected.");
        require(TOKENS > 0, "All tokens sold");
        require(member.isMember(msg.sender), "The user did not register in the pre-registration");

        uint256 value_to_buy_father = msg.value;
        uint256 value_to_buy = msg.value;
        uint256 value_to_return = 0;
        uint256 total_tokens = 0;

        //TIME VARIABLES FOR TESTS
        value_to_buy_father = value_to_buy_father.mul(100000);
        value_to_buy = value_to_buy.mul(100000);
        //TIME VARIABLES FOR TESTS

        if(now >= ROUND_1_START_TIME && now <= ROUND_1_END_TIME){
            require(whitelistCapsRound_1[msg.sender] > 0, "You can't buy Token");
            require(value_to_buy >= ROUND_1_CAP_MIN, "The sent value must be greater");
            require(value_to_buy <= ROUND_1_CAP_MAX, "The sent value must be less");
            require(HARDCAP_ROUND_1 > 0, "The round is already collected");
            require(TOKENS_ROUND_1 > 0, "All tokens in the round were sold");

            if(whitelistCapsRound_1[msg.sender] >= value_to_buy){
                value_to_buy = value_to_buy;
            } else {
                value_to_return = value_to_buy.sub(whitelistCapsRound_1[msg.sender]);
                value_to_buy = value_to_buy.sub(value_to_return);
            }

            if(HARDCAP_ROUND_1 < value_to_buy){
                if(value_to_buy_father > HARDCAP_ROUND_1){
                    value_to_return = value_to_buy_father.sub(HARDCAP_ROUND_1);
                    value_to_buy = value_to_buy_father.sub(value_to_return);
                } else {
                    value_to_buy = value_to_buy_father.sub(value_to_buy_father.sub(HARDCAP_ROUND_1));
                }
            }

            total_tokens = value_to_buy.mul(TOKEN_PER_BNB);

            if(TOKENS_ROUND_1 < total_tokens ){
                total_tokens = total_tokens.sub(total_tokens.sub(TOKENS_ROUND_1));
            }

            if(value_to_buy > 0 && total_tokens > 0){
                whitelistCapsRound_1[msg.sender] = whitelistCapsRound_1[msg.sender].sub(value_to_buy);
                contributions_1[msg.sender] = contributions_1[msg.sender].add(value_to_buy);
                HARDCAP = HARDCAP.sub(value_to_buy);
                HARDCAP_ROUND_1 = HARDCAP_ROUND_1.sub(value_to_buy);
                TOKENS = TOKENS.sub(total_tokens);
                TOKENS_ROUND_1 = TOKENS_ROUND_1.sub(total_tokens);

                if(TOKENS_ROUND_1 == 0){
                    ROUND_1_END_TIME = now;
                    ROUND_2_START_TIME = now;
                    ROUND_2_END_TIME = now + 3 days;
                }

                token.transfer(msg.sender, total_tokens);

                if(TOKENS_SPONSORS > 0){
                    address[] memory refTree = member.getParentTree(msg.sender, 3);
                    for (uint256 i = 0; i < 3; i++) {
                        if (refTree[i] != address(0)) {
                            uint256 refAmount = total_tokens.mul(refPercent[i]).div(100);
                            if(TOKENS_SPONSORS <= refAmount){
                                refAmount = TOKENS_SPONSORS;
                            }
                            TOKENS_SPONSORS = TOKENS_SPONSORS.sub(refAmount);
                            token.transfer(refTree[i], refAmount);
                            if(TOKENS_SPONSORS == 0){
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }

                if(value_to_return > 0){
                    //TIME VARIABLES FOR TESTS
                    value_to_return = value_to_return.div(100000);
                    //TIME VARIABLES FOR TESTS
                    address(uint160(msg.sender)).transfer(value_to_return);
                }

                emit eventSaleToken(1, msg.sender, value_to_buy, total_tokens, value_to_return, now);

            } else {
                revert("Token sale error");   
            }
        } else {
            require(ROUND_2_END_TIME > now, "Stage 2 sale ended");
            require(whitelistCapsRound_2[msg.sender] > 0, "You can't buy tokens");
            require(value_to_buy >= ROUND_2_CAP_MIN, "The sent value must be greater");
            require(value_to_buy <= ROUND_2_CAP_MAX, "The sent value must be less");
            require(HARDCAP_ROUND_2 > 0, "The round is already collected");
            require(TOKENS_ROUND_2 > 0, "All tokens in the round were sold");

            if(whitelistCapsRound_2[msg.sender] >= value_to_buy){
                value_to_buy = value_to_buy;
            } else {
                value_to_return = value_to_buy.sub(whitelistCapsRound_2[msg.sender]);
                value_to_buy = value_to_buy.sub(value_to_return);
            }

            if(HARDCAP_ROUND_2 < value_to_buy){
                if(value_to_buy_father > HARDCAP_ROUND_2){
                    value_to_return = value_to_buy_father.sub(HARDCAP_ROUND_2);
                    value_to_buy = value_to_buy_father.sub(value_to_return);
                } else {
                    value_to_buy = value_to_buy_father.sub(value_to_buy_father.sub(HARDCAP_ROUND_2));
                }
            }

            total_tokens = value_to_buy.mul(TOKEN_PER_BNB);

            if(TOKENS_ROUND_2 < total_tokens ){
                total_tokens = total_tokens.sub(total_tokens.sub(TOKENS_ROUND_2));
            }

            if(value_to_buy > 0 && total_tokens > 0){
                whitelistCapsRound_2[msg.sender] = whitelistCapsRound_2[msg.sender].sub(value_to_buy);
                contributions_2[msg.sender] = contributions_2[msg.sender].add(value_to_buy);
                HARDCAP = HARDCAP.sub(value_to_buy);
                HARDCAP_ROUND_2 = HARDCAP_ROUND_2.sub(value_to_buy);
                TOKENS = TOKENS.sub(total_tokens);
                TOKENS_ROUND_2 = TOKENS_ROUND_2.sub(total_tokens);

                token.transfer(msg.sender, total_tokens);

                if(TOKENS_SPONSORS > 0){
                    address[] memory refTree = member.getParentTree(msg.sender, 3);
                    for (uint256 i = 0; i < 3; i++) {
                        if (refTree[i] != address(0)) {
                            uint256 refAmount = total_tokens.mul(refPercent[i]).div(100);
                            if(TOKENS_SPONSORS <= refAmount){
                                refAmount = TOKENS_SPONSORS;
                            }
                            TOKENS_SPONSORS = TOKENS_SPONSORS.sub(refAmount);
                            token.transfer(refTree[i], refAmount);
                            if(TOKENS_SPONSORS == 0){
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }

                if(value_to_return > 0){
                    //TIME VARIABLES FOR TESTS
                    value_to_return = value_to_return.div(100000);
                    //TIME VARIABLES FOR TESTS
                    address(uint160(msg.sender)).transfer(value_to_return);
                }

                if(TOKENS_ROUND_2 == 0){
                    ROUND_2_END_TIME = now;
                }                

                emit eventSaleToken(2, msg.sender, value_to_buy, total_tokens, value_to_return, now);

            } else {
                revert("Token sale error");
            }
        }
    }

    function claim() external {
        require((ROUND_2_END_TIME + 1 days) < now, "You still can't claim");
        require(liquidityLocked == false, "The funds were sent to the LP");
        uint balance = contributions_1[msg.sender].add(contributions_2[msg.sender]);
        require(balance > 0, "You have no balance to claim");
        if(balance >= address(this).balance){
            address(uint160(msg.sender)).transfer(balance);
            contributions_1[msg.sender] = 0;
            contributions_2[msg.sender] = 0;
        }
    }

    function addAndLockLiquidity() external {
        require(liquidityLocked == false, "Already settled previously");
        require(HARDCAP == 0, "Collection has not finished");
        require(TOKENS == 0, "Collection has not finished");
        uint256 amountWBNB = address(this).balance;
        uint256 tokens_solds = tokensSend(address(this).balance);
        uint256 tokens_solds_min = tokens_solds.sub(tokens_solds.mul(1).div(100));
        uint256 value_min = address(this).balance.sub(address(this).balance.mul(1).div(100));
        masterchef.mint(address(this), tokens_solds);
        token.approve(address(uniswapRouter), tokens_solds);
        uniswapRouter.addLiquidityETH
        { value: amountWBNB }
        (
            address(token),
            tokens_solds,
            tokens_solds_min,
            value_min,
            address(this),
            now.add(1800)
        );
        liquidityLocked = true;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getReserves(address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Router02(masterchef.tokenLP()).getReserves();
        (reserveA, reserveB) = address(tokenA) == address(token0) ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amount, uint reserveA, uint reserveB) public view returns (uint) {
        return uniswapRouter.quote(amount, reserveB, reserveA);
    }    

    function tokensSend(uint valueWEI) public view returns(uint256){
        (uint reserveA, uint reserveB) = getReserves(address(token), address(WBNB));
        return uniswapRouter.quote(valueWEI, reserveB, reserveA);
    }    

    function balanceToClaim(address _user) public view returns(uint256){
        if((ROUND_2_END_TIME + 1 days) < now){
            return contributions_1[_user].add(contributions_2[_user]);
        } else {
            return 0;
        }
    }

    function getStartStage_1() public view returns (uint256) {
        return ROUND_1_START_TIME - now;
    }

    function getEndStage_1() public view returns (uint256) {
        return ROUND_1_END_TIME - now;
    }

    function getStartStage_2() public view returns (uint256) {
        return ROUND_2_START_TIME - now;
    }

    function getEndStage_2() public view returns (uint256) {
        return ROUND_2_END_TIME - now;
    }
    
    function getDateClaim() public view returns (uint256) {
        return (ROUND_2_END_TIME + 1 days) - now;
    }
    
    function ICO_balance() public view returns(uint256){
        return address(this).balance;
    }
    function myBalance(address _user) public view returns(uint256){
        return token.balanceOf(_user);
    }


    //TIME VARIABLES FOR TESTS
    function set_ROUND_1_START_TIME(uint256 _time) external onlyOwner {
        ROUND_1_START_TIME = _time;
    }

    function set_ROUND_1_END_TIME(uint256 _time) external onlyOwner {
        ROUND_1_END_TIME = _time;
    }

    function set_ROUND_2_START_TIME(uint256 _time) external onlyOwner {
        ROUND_2_START_TIME = _time;
    }

    function set_ROUND_2_END_TIME(uint256 _time) external onlyOwner {
        ROUND_2_END_TIME = _time;
    }

    function set_Locked(bool _value) external onlyOwner {
        liquidityLocked = _value;
    }    
    //TIME VARIABLES FOR TESTS


    event eventSaleToken(uint indexed round, address indexed user, uint256 balance, uint256 tokens, uint256 to_return, uint256 time);

}