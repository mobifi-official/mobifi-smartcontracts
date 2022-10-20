const {expect} = require("chai");
const {parseEther} = require('ethers/lib/utils');
const {waffle, ethers} = require("hardhat");
const hre = require("hardhat");

describe("MobiFi contract", function () {
    let mobiFiContract;
    let mobiFi;
    let owner;
    let user1;
    let user2;
    let addrs;

    beforeEach(async function () {
        [owner, user1, user2, ...addrs] = await ethers.getSigners();
        mobiFiContract = await ethers.getContractFactory("MobiFi");
        mobiFi = await mobiFiContract.deploy(owner.address, parseEther("10000"));
        await mobiFi.deployed();
    });

    describe("Check default value at deployement", function () {
        it("Total supply should be 10000", async function () {
            expect(await mobiFi.totalSupply()).to.equal(parseEther("10000"));
        });

        it("Token address should be same as preset", async function () {
            expect(await mobiFi.tokenAddress()).to.equal(mobiFi.address);
        });

        it('Token address should be same as MobiFi', async function () {
            expect(await mobiFi.tokenAddress()).to.equal(mobiFi.address);
        });
    });

    describe("Check MobiFi contract", async function () {
        it('should not mint token to non minter account', async function () {
            await mobiFi.mint(user1.address, parseEther("100"));
            expect(await mobiFi.balanceOf(user1.address)).to.be.revertedWith();
        });

        it('should mint token to minter account', async function () {
            await mobiFi.connect(owner).AddMinter(user1.address);
            await mobiFi.connect(user1).mint(user1.address, parseEther("1"));
            expect(await mobiFi.balanceOf(user1.address)).to.equal(parseEther("1"));
        });

        it("Should not allow revoked minter to mint", async function () {
            await mobiFi.connect(owner).AddMinter(user1.address);
            await mobiFi.connect(owner).RemoveMinter(user1.address);
            await mobiFi.connect(user1).mint(user1.address, parseEther("1"));
            expect(await mobiFi.balanceOf(user1.address)).to.be.revertedWith();
        });

        it("Should not allow non minter to add minter", async function () {
          console.log(mobiFi.MaxSupply());
        })
    });
});
