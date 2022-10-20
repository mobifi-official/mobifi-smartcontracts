const {expect} = require("chai");
const {parseEther} = require('ethers/lib/utils');
const {waffle, ethers} = require("hardhat");
const hre = require("hardhat");


describe("PaidHunterAlex contract", function () {
    let tokenAddress;
    let paidHunterAlexContract;
    let mobiFiContract;
    let paidHunterAlex;
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
        tokenAddress = mobiFi.address;
        paidHunterAlexContract = await ethers.getContractFactory("PaidHunterAlexTestV1");
        paidHunterAlex = await paidHunterAlexContract.deploy(tokenAddress, parseEther("0.01"), owner.address);
        await paidHunterAlex.deployed();
    });

    describe("Check default value at deployement", function () {
        it("Total supply should be 10000", async function () {
            expect(await mobiFi.totalSupply()).to.equal(parseEther("10000"));
        });
        // failed due to internal call
        it("Token address should be same as preset", async function () {
            expect(await mobiFi.tokenAddress()).to.equal(tokenAddress);
        });
        // failed due to internal call
        it('Token address should be same as MobiFi', async function () {
            expect(await paidHunterAlex.tokenAddress()).to.equal(tokenAddress);
        });
        it('Price should be same as preset', async function () {
            expect(await paidHunterAlex.price()).to.equal(parseEther("0.01"));
        });
        // failed due to internal call
        it('mobiFi address should be same as preset', async function () {
            expect(await paidHunterAlex.mobiFiAddress()).to.equal(owner.address);
        });
    });

    describe("Check PaidHunterAlex contract", async function () {
        it("Should allow user to mint a token", async function () {
            await mobiFi.approve(paidHunterAlex.address, parseEther("0.01"));
            await paidHunterAlex.mintNFT(user1.address, 2);
            expect(await paidHunterAlex.balanceOf(user1.address)).to.equal(1);
        });

        it("Should not allow user to mint a token if not approved", async function () {
            await mobiFi.approve(paidHunterAlex.address, parseEther("0.01"));
            await paidHunterAlex.mintNFT(user1.address, 2);
            await expect(paidHunterAlex.mintNFT(user1.address, 3)).to.be.revertedWith("ERROR_TOKEN_ALREADY_MINTED");
        });

        it("Should not allow user to mint a token if price not match", async function () {
            await mobiFi.approve(paidHunterAlex.address, parseEther("0.005"));
            await expect(paidHunterAlex.mintNFT(user1.address, 2)).to.be.revertedWith("ERC20: insufficient allowance");
        });

        // Function is not called anywhere thus no information updated for check -- addressHasMintedNFT(question)
        // it("Should return true if user already minted the NFTs", async function () {
        //     await mobiFi.approve(paidHunterAlex.address, parseEther("0.01"));
        //     await paidHunterAlex.mintNFT(user1.address, 2);
        //     console.log(await paidHunterAlex.addressHasMintedNFT(user1.address));
        //     await expect(paidHunterAlex.addressHasMintedNFT(user1.address)[2]).to.be.equal(true);
        // });

        // this will fail because of the burn function is internal
        it("Should burn a token", async function () {
            await mobiFi.approve(paidHunterAlex.address, parseEther("0.01"));
            await paidHunterAlex.mintNFT(user1.address, 2);
            await paidHunterAlex.burn(2);
            expect(await paidHunterAlex.balanceOf(user1.address)).to.equal(0);
        });


    });

    describe("Check Role execution in PaidHunterAlex Contract", async function () {
        it('should grant user the minter rola',async function () {
            await paidHunterAlex.grantMinterRole(user1.address);
            expect(await paidHunterAlex.hasRole(paidHunterAlex.MINTER_ROLE(), user1.address)).to.equal(true);
        });
        // revokeMinterRole
        it('should revoke user the minter rola',async function () {
            await paidHunterAlex.grantMinterRole(user1.address);
            await paidHunterAlex.revokeMinterRole(user1.address);
            expect(await paidHunterAlex.hasRole(paidHunterAlex.MINTER_ROLE(), user1.address)).to.equal(false);
        });

        it("Should only allow owner to revoke minter role", async function () {
            await paidHunterAlex.grantMinterRole(user1.address);
            await expect(paidHunterAlex.connect(user1).revokeMinterRole(user1.address)).to.be
                .revertedWith("AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        });

        it("Should return true if user is minter", async function () {
            await paidHunterAlex.grantMinterRole(user1.address);
            expect(await paidHunterAlex.checkIfAddressHasMinterRole(user1.address)).to.equal(true);
        });

        it("Should return false if user is not minter", async function () {
            expect(await paidHunterAlex.checkIfAddressHasMinterRole(user1.address)).to.equal(false);
        });

        it("Should allow minter to mint for free", async function () {
            await paidHunterAlex.grantMinterRole(user1.address);
            await paidHunterAlex.connect(user1).mintNFT(user1.address, 2);
            expect(await paidHunterAlex.balanceOf(user1.address)).to.equal(1);
        });
    });
});
