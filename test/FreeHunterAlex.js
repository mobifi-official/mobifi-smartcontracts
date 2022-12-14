const {expect} = require("chai");
const {parseEther} = require('ethers/lib/utils');
const {waffle, ethers} = require("hardhat");
const hre = require("hardhat");

describe("PaidHunterAlex contract", function () {
    let FreeHunterAlexContract;
    let freeHunterAlex;
    let owner;
    let user1;
    let user2;
    let user3;
    let user4;
    let addrs;

    beforeEach(async function () {
        [owner, user1, user2, user3, user4, ...addrs] = await ethers.getSigners();
        FreeHunterAlexContract = await ethers.getContractFactory("MobiFiFreeNFTSmartContract");
        freeHunterAlex = await FreeHunterAlexContract.deploy("test", "test2", 2, "mobifi.io");
        await freeHunterAlex.deployed();
    });

    describe("Check default value at deployement", function () {
        it("Total supply should be 100", async function () {
            expect(await freeHunterAlex.maxSupply()).to.equal(2);
        });
        it('should return toke name', async function () {
            expect(await freeHunterAlex.name()).to.equal("test");
        });
        it('should return toke symbol', async function () {
            expect(await freeHunterAlex.symbol()).to.equal("test2");
        });
    });

    describe("Check FreeHunterAlex contract access control", async function () {
        it("Should not mint token to non minter account", async function () {
            await expect(freeHunterAlex.connect(user1).mintNFT(user1.address, 1)).to.be.reverted;
        });

        it("Should mint token to minter account", async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(user1).mintNFT(user1.address, 1);
            expect(await freeHunterAlex.balanceOf(user1.address)).to.equal(1);
        });

        it("Should return if user has a minter role", async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            expect(await freeHunterAlex.checkIfAddressHasMinterRole(user1.address)).to.equal(true);
        });

        it("Should return if user doesnt have a minter role", async function () {
            expect(await freeHunterAlex.checkIfAddressHasMinterRole(user1.address)).to.equal(false);
        });

        it("Should not allow revoked minter to mint", async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(owner).revokeMinterRole(user1.address);
            await expect(freeHunterAlex.connect(user1).mintNFT(user1.address, 1)).to.be.reverted;
        });

        it("Should not allow non minter to add minter", async function () {
            await expect(freeHunterAlex.connect(user1).grantMinterRole(user2.address)).to.be.reverted;
        });

        it("Should not allow non minter to remove minter", async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await expect(freeHunterAlex.connect(user2).revokeMinterRole(user1.address)).to.be.reverted;
        });

        it("Should return false if user is revoked", async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(owner).revokeMinterRole(user1.address);
            expect(await freeHunterAlex.checkIfAddressHasMinterRole(user1.address)).to.equal(false);
        });
    });

    describe("Check FreeHunterAlex contract for mint", async function () {
        it('should return true if user minted the NFT', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            freeHunterAlex.connect(user1).mintNFT(user1.address, "1");
            expect(await freeHunterAlex.connect(user1).addressHasMintedNFT(user1.address)).to.equal(true);
        });

        it('should not allow same user to mint twice', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(user1).mintNFT(user1.address, 1);
            await expect(freeHunterAlex.connect(user1).mintNFT(user1.address, 1)).to.be
                .revertedWith('ERROR_ADDRESS_ALREADY_MINTED_CHARACTER');
        });
        it('should not allow users to mint on same id', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(owner).grantMinterRole(user2.address);
            await freeHunterAlex.connect(user1).mintNFT(user1.address, 1);
            await expect(freeHunterAlex.connect(user2).mintNFT(user2.address, 1)).to.be
                .revertedWith('ERROR_TOKEN_ALREADY_MINTED');
        });

        it('should not allow users to mint more than max supply', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user4.address);
            await expect(freeHunterAlex.connect(user4).mintNFT(user4.address, "10")).to.be
                .revertedWith("ERROR_NOT_CORRECT_URI_INPUT");
        });

        it('Should pause the mint if paused', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(owner).setPaused(true);
            await expect(freeHunterAlex.connect(user1).mintNFT(user1.address, 2)).to.be
                .revertedWith('CONTRACT_MINTING_PAUSED');
        });

        it('Should only allow mint action if both users are minter', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await freeHunterAlex.connect(owner).grantMinterRole(user2.address);
            await freeHunterAlex.connect(user1).mintNFT(user2.address, "1");
            expect(await freeHunterAlex.connect(user1).balanceOf(user2.address)).to.equal(1)
        });

        it('Should not allow mint action if one user is not minter', async function () {
            await freeHunterAlex.connect(owner).grantMinterRole(user1.address);
            await expect(freeHunterAlex.connect(user1).mintNFT(user2.address, "1")).to.be
                .revertedWith('ERROR_ADDRESS_NOT_MINTER');
        });

        it("should generate two same token ids", async function () {
            let num1 = await freeHunterAlex.st2num("tim");
            expect(num1).to.equal(7431);
        });
    });
});
