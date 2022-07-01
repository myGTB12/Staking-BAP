// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./rewardToken.sol";

contract Staking is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct UserInfor{
        uint256 amount;
        uint256 rewardDebt;
        uint256 accumulatedStakingPower;
    }

    struct PoolInfor{
        IERC20 rewardToken;
        IERC20 lpToken;
        uint allocPoint;
        uint lastRewardBlock;
        uint accRewardPershared;
        bool isStarted;
    }
    
    uint public rewardPerBlock;

    PoolInfor[] public poolInfo;

    mapping(uint => mapping(address => UserInfor)) public userInfo;

    uint public totalAllocPoint = 0;

    uint public startBlock;

    uint public constant BLOCKS_PER_WEEK = 45000;
    
    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount);

    constructor(
        uint _rewardPerBlock,
        uint _startBlock
    )public{
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;        
    }
    
    function poolLength() public view returns(uint){
        return poolInfo.length;
    }
    function setRewardPerBlock(uint _rewardPerBlock) public onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }
    function checkDuplicate(IERC20 _lpToken) internal view{
        uint256 leng = poolInfo.length;
        for(uint i = 0; i < leng; i++){
            require(poolInfo[i].lpToken != _lpToken, "existing pool");
        }
    }

    function add(uint _allocPoint, IERC20 _lpToken, IERC20 _rewardToken, bool _withUpdate, uint _lastRewardBlock) public onlyOwner{
        checkDuplicate(_lpToken);
        if(_withUpdate){
            massUpdatePools();
        }
        if(block.number < startBlock){
            if(_lastRewardBlock == 0){
                _lastRewardBlock = startBlock;
            }else{
                if(_lastRewardBlock < startBlock){
                    _lastRewardBlock = startBlock;
                }
            }
        }else{
            if(_lastRewardBlock == 0 || _lastRewardBlock < block.number){
                _lastRewardBlock = block.number;
            }
        }
        bool _isStarted = (_lastRewardBlock <= startBlock) || (_lastRewardBlock <= block.number);
        poolInfo.push(PoolInfor({
            rewardToken: _rewardToken,
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: _lastRewardBlock,
            accRewardPershared: 0,
            isStarted: _isStarted
        }));
        if(_isStarted){
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }
    
    function set(uint _pid, uint _allocPoint) public onlyOwner{
        massUpdatePools();
        PoolInfor storage pool = poolInfo[_pid];
        if(pool.isStarted){
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
    }

    function pendingBearn(uint _pid, address _user) external view returns(uint){
        PoolInfor storage pool = poolInfo[_pid];
        UserInfor storage user = userInfo[_pid][_user];
        uint accRewardPerShare = pool.accRewardPershared;
        uint lpSupply = pool.lpToken.balanceOf(address(this));
        if(block.number > pool.lastRewardBlock && lpSupply != 0){
            uint _numBlocks = block.number.sub(pool.lastRewardBlock);
            if(totalAllocPoint > 0){
                uint _reward = _numBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(_reward.mul(1e12).div(lpSupply)); 
            }
        } 
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public{
        uint length = poolInfo.length;
        for(uint _pid = 0; _pid < length; _pid++){
            updatePool(_pid);
        }
    }
    function updatePool(uint _pid) public{
        PoolInfor storage pool = poolInfo[_pid];
        if(block.number <= pool.lastRewardBlock){
            return;
        }           
        uint lpSupply = pool.lpToken.balanceOf(address(this)); 
        if(lpSupply == 0){
            pool.lastRewardBlock = block.number;
            return;
        }
        if(!pool.isStarted){
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if(totalAllocPoint > 0){
            uint _numBlocks = block.number.sub(pool.lastRewardBlock);
            uint _reward = _numBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accRewardPershared = pool.accRewardPershared.add(_reward.mul(1e12).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }
    function deposit(uint _pid, uint _amount) public{
        PoolInfor storage pool = poolInfo[_pid];
        UserInfor storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if(user.amount > 0){
            uint pending = user.amount.mul(pool.accRewardPershared).div(1e12).sub(user.rewardDebt);
            if(pending > 0){
                user.accumulatedStakingPower = user.accumulatedStakingPower.add(pending);
                pool.rewardToken.safeTransfer(msg.sender, pending);
            }
            if(_amount > 0){
                pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amount = user.amount.add(_amount);
            }
            user.rewardDebt = user.amount.mul(pool.accRewardPershared).div(1e12);
            emit Deposit(msg.sender, _pid, _amount);
        }
    }
    function withdraw(uint _pid, uint _amount) public{
        PoolInfor storage pool = poolInfo[_pid];
        UserInfor storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "balance: not enough ");
        updatePool(_pid);
        uint pending = user.amount.mul(pool.accRewardPershared).div(1e12).sub(user.rewardDebt);
        if(pending > 0){
            user.accumulatedStakingPower = user.accumulatedStakingPower.add(pending);
            pool.rewardToken.safeTransfer(msg.sender, pending);
        }
        if(_amount > 0){
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.rewardDebt.mul(pool.accRewardPershared).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
}