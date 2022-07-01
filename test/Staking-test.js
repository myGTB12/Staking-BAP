
const {ethers} = require("hardhat");
const {expect} = require("chai");


describe("Staking", function(){
    let owner;
    let address1;
    let address2;
    let Staking;
    let stakingContract;
    let rewardToken;
    let RewardToken;
    let LPToken;
    let lptoken;

    beforeEach(async function(){
        Staking = await ethers.getContractFactory("Staking");
        RewardToken = await ethers.getContractFactory("RewardTokenn");
        [owner, address1, address2] = await ethers.getSigners();
        stakingContract = await Staking.deploy(2000000, 1658880000);
        rewardToken = await RewardToken.deploy();
        LPToken = await ethers.getContractFactory("LPToken");
        lptoken = await LPToken.deploy();
        await lptoken.transfer(address1.address, 2000);
    });

    describe("Staking constract ", function(){
        it("Constructor parameter should correct", async function(){
            expect(await stakingContract.rewardPerBlock()).to.equal(2000000);    
            expect(await stakingContract.startBlock()).to.equal(1658880000);    
        });
        
        it("add", async function(){
            await stakingContract.add(100, lptoken.address, rewardToken.address, false, 100);
            expect(await stakingContract.poolLength()).to.equal(1); 
             
        });

        it('deposit', async function(){
            await stakingContract.add(100, lptoken.address, rewardToken.address, true, 100);
            await lptoken.approve(stakingContract.address, 500);
            await stakingContract.connect(address1).deposit(0, 500);
            // await stakingContract.connect(address1).deposit(0, 0);
            console.log(await lptoken.balanceOf(address1.address));
            expect(await lptoken.balanceOf(address1.address)).to.equal(1950);
        });
    });
})