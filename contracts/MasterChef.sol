// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

import "./Token.sol";
import "./TokenGBT.sol";
import "./interfaces/IMigratorChef.sol";
import "./interfaces/IMembers.sol";
import "./interfaces/IPancakeFactory.sol";


// MasterChef is the master of Token. He can make Token and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once TOKEN is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. TOKENs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that TOKENs distribution occurs.
        uint256 accTokenPerShare; // Accumulated TOKENs per share, times 1e12. See below.
    }

    // The TOKEN!
    Token public token;
    // The GBT TOKEN!
    TokenGBT public gbt;
    // Members
    IMembers public member;
    // Router address.
    address public router;
    // Factory address.
    address public factory;
    // WBNB address.
    address public wbnb;
    // LP address.
    address public tokenLP;
    // LP GBT address.
    address public gbtLP;
    // Dev address.
    address public devaddr;
    // Controller address
    address public controlleraddr;
    // Lottery address.
    address public lotteryaddr;
    // Tokens created per block.
    uint256 public tokenPerBlock;
    // Bonus muliplier for early token makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when TOKEN mining starts.
    uint256 public startBlock;
    // Percentage of referrals
    uint256[5] public refPercent = [0, 0, 0, 0, 0];

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Referrals(address indexed user, address indexed ref, uint256 indexed pid, uint256 amount);

    constructor(
        Token _token,
        TokenGBT _gbt,
        IMembers _member,
        address _router,
        address _factory,
        address _wbnb,
        address _devaddr,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        bool _checkFactoryDEX
    ) public {
        token = _token;
        gbt = _gbt;
        member = _member;
        devaddr = _devaddr;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        router = _router;
        factory = _factory;
        wbnb = _wbnb;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _token,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accTokenPerShare: 0
        }));

        totalAllocPoint = 1000;

        if(_checkFactoryDEX){
            if (IPancakeFactory(factory).getPair(address(token), _wbnb) == address(0)) {
                IPancakeFactory(factory).createPair(address(token), _wbnb);
                tokenLP = IPancakeFactory(factory).getPair(address(token), _wbnb);
                poolInfo.push(PoolInfo({
                    lpToken: IBEP20(tokenLP),
                    allocPoint: 1000,
                    lastRewardBlock: startBlock,
                    accTokenPerShare: 0
                }));
                totalAllocPoint = totalAllocPoint.add(1000);
            }

            if (IPancakeFactory(factory).getPair(address(gbt), _wbnb) == address(0)) {
                IPancakeFactory(factory).createPair(address(gbt), _wbnb);
                gbtLP = IPancakeFactory(factory).getPair(address(gbt), _wbnb);
            }
        }

    }

    function setPercent(uint256 r_1, uint256 r_2, uint256 r_3, uint256 r_4, uint256 r_5) external onlyOwner {
        refPercent[0] = r_1;
        refPercent[1] = r_2;
        refPercent[2] = r_3;
        refPercent[3] = r_4;
        refPercent[4] = r_5;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function setTokenPerBlock(uint256 _tokenPerBlock) external onlyOwner {
        tokenPerBlock = _tokenPerBlock;
    } 

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Creation of TOKENs for referrals
    function referrals(address _user, uint256 _pid, uint256 _amount) public {
        address[] memory refTree = member.getParentTree(_user, 5);
        for (uint256 i = 0; i < 5; i++) {
            if (refTree[i] != address(0) && refPercent[i] > 0 && _amount > 0) {
                uint256 refAmount = _amount.mul(refPercent[i]).div(100 ether);
                if(refAmount > 0){
                    token.mint(refTree[i], refAmount);
                    emit Referrals(_user, refTree[i], _pid, refAmount);
                }
            } else {
                break;
            }
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accTokenPerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's TOKEN allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IBEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending TOKENs on frontend.
    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        token.mint(devaddr, tokenReward.div(10));
        token.mint(address(gbt), tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for TOKEN allocation.
    function deposit(uint256 _pid, uint256 _amount, address ref) public {

        require (_pid != 0, 'deposit token by staking');

        if(member.isMember(ref) == false){
            ref = member.membersList(0);
        }

        if(member.isMember(msg.sender) == false){
            member.addMember(msg.sender, ref);
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTokenTransfer(msg.sender, pending);
                referrals(msg.sender, _pid, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw token by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeTokenTransfer(msg.sender, pending);
            referrals(msg.sender, _pid, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake token tokens to MasterChef
    function enterStaking(uint256 _amount, address ref) public {
        
        if(member.isMember(ref) == false){
            ref = member.membersList(0);
        }

        if(member.isMember(msg.sender) == false){
            member.addMember(msg.sender, ref);
        }

        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTokenTransfer(msg.sender, pending);
                referrals(msg.sender, 0, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);

        gbt.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw token tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeTokenTransfer(msg.sender, pending);
            referrals(msg.sender, 0, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);

        gbt.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough TOKENs.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        gbt.safeTokenTransfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function controller(address _controlleraddr) public onlyOwner {
        controlleraddr = _controlleraddr;
    }

    function mintController(address _user, uint256 _amount) public {
        require(msg.sender == controlleraddr, "controller: wut?");
        token.mint(_user, _amount);
    } 

    function lottery(address _lotteryaddr) public onlyOwner {
        lotteryaddr = _lotteryaddr;
    }

    function lotteryGain(address _user, uint256 _amount) public {
        require(msg.sender == lotteryaddr, "lottery: wut?");
        token.mint(_user, _amount);
    }    

}

