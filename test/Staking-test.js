
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
        stakingContract = await Staking.deploy(2000000, 0);
        rewardToken = await RewardToken.deploy();
        LPToken = await ethers.getContractFactory("LPToken");
        lptoken = await LPToken.deploy();
        await lptoken.transfer(address1.address, 2000);
        await lptoken.transfer(address2.address, 5000);
        await rewardToken.transfer(stakingContract.address, 1000000);
    });

    describe("Staking constract ", function(){
        it("Constructor parameter should correct", async function(){
            expect(await stakingContract.rewardPerBlock()).to.equal(2000000);    
            expect(await stakingContract.startBlock()).to.equal(0);    
        });
        
        it("add", async function(){
            await stakingContract.add(100, lptoken.address, rewardToken.address, false, 100);
            expect(await stakingContract.poolLength()).to.equal(1);          
        });

        it('deposit/withdraw', async function(){
            await stakingContract.add(1000, lptoken.address, rewardToken.address, false, 10);

            await (await lptoken.connect(address1).approve(stakingContract.address, 500)).wait();
            await stakingContract.connect(address1).deposit(0, 500);
            expect(await lptoken.balanceOf(address1.address)).to.equal(1500);
            expect(await lptoken.balanceOf(stakingContract.address)).to.equal(500);            
            
            console.log(await rewardToken.balanceOf(stakingContract.address));
            await stakingContract.connect(address1).withdraw(0, 300);
            expect(await lptoken.balanceOf(stakingContract.address)).to.equal(200);
            expect(await lptoken.balanceOf(address1.address)).to.equal(1800);  
            
            await(await lptoken.connect(address2).approve(stakingContract.address, 2000)).wait();
            await stakingContract.connect(address2).deposit(0, 2000);
            expect(await lptoken.balanceOf(address2.address)).to.equal(3000);
            expect(await lptoken.balanceOf(stakingContract.address)).to.equal(2200);

            await stakingContract.connect(address2).withdraw(0, 1200);
            expect(await lptoken.balanceOf(stakingContract.address)).to.equal(1000);
            expect(await lptoken.balanceOf(address2.address)).to.equal(4200);
        });
    });
})