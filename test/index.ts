import { expect } from 'chai';
import { BigNumber } from 'bignumber.js';
import { ethers, network} from 'hardhat';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {MNFT1155, MNFT721, MarketPlace, MarketPlacewithAutobid} from '../typechain'

async function getCurrentTime(){
    return (
      await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
    ).timestamp;
  }

async function evm_increaseTime(seconds : number){
    await network.provider.send("evm_increaseTime", [seconds]);
    await network.provider.send("evm_mine");
  }

describe("Testing the Market Place Contract", () =>{
    let mP : MarketPlace;
    let mPAB : MarketPlacewithAutobid;
    let mNFT1155 : MNFT1155;
    let mNFT721: MNFT721;
    let clean : any;
    let owner : SignerWithAddress, signertwo : SignerWithAddress, signerthree: SignerWithAddress;
    
    before(async () => {

        [owner, signertwo, signerthree] = await ethers.getSigners();

        const MP = await ethers.getContractFactory("MarketPlace");
        mP = <MarketPlace>(await MP.deploy());
        await mP.deployed();

        const MPab = await ethers.getContractFactory("MarketPlacewithAutobid");
        mPAB = <MarketPlacewithAutobid>(await MPab.deploy());
        await mPAB.deployed();

        const MNFT115 = await ethers.getContractFactory("MNFT1155");
        mNFT1155 = <MNFT1155>(await MNFT115.deploy());
        await mNFT1155.deployed();

        const MNFT7 = await ethers.getContractFactory("MNFT721");
        mNFT721 = <MNFT721>(await MNFT7.deploy());
        await mNFT721.deployed();
     
    });

    describe("Checking setNFT721ContractAddress is run correctly", () => {
        it("Checks the setNFT721ContractAddress is updated correctly or not", async () => {
          await mP.setNFT721ContractAddress(mNFT721.address);
            expect(await mP.NFT721Contract()).to.be.equal(await mNFT721.address);
        })

        it("Checks the setNFT1155ContractAddress is updated correctly or not", async () => {
          await mP.setNFT1155ContractAddress(mNFT1155.address);
            expect(await mP.NFT1155Contract()).to.be.equal(await mNFT1155.address);
        })

        it("Checks the setAuctionListingPrice is updated correctly or not", async () => {
          await mP.setAuctionListingPrice(10**10);
          let stringAuction = await (await mP.AuctionListingPrice()).toString();
            await expect(stringAuction).to.be.equal(await (10**10).toString());
        })

        it("Checks the setListingPrice is updated correctly or not", async () => {
          await mP.setListingPrice(10**10);
          let stringAuction = await (await mP.ListingPrice()).toString();
            await expect(stringAuction).to.be.equal(await (10**10).toString());
        })

        it("Checks the create Function is working correctly or not by creating NFT721", async () => {
          await mP.connect(owner).createItem(false, "randomTOKENURIdata.json", 20);
          expect(await mNFT721.connect(owner).balanceOf(owner.address)).to.be.equal(1);
        })
      
        it("Checks the create Function is working correctly or not by creating NFT1155", async () => {
          await mP.connect(owner).createItem(true, "randomTOKENURIdata.json", 20);
          expect(await mNFT1155.connect(owner).balanceOf(owner.address, 1)).to.be.equal(20);
        })

        it("Checks the approve Function is working correctly or not for NFT721", async () => {
          await mNFT721.connect(owner).setApprovalForAll(mP.address, true);
          expect(await mNFT721.connect(owner).isApprovedForAll(owner.address, mP.address)).to.be.equal(true);
        })

        it("Checks the approve Function is working correctly or not for NFT1155", async () => {
          await mNFT1155.connect(owner).setApprovalForAll(mP.address, true);
          expect(await mNFT1155.connect(owner).isApprovedForAll(owner.address, mP.address)).to.be.equal(true);
        })

        it("Checks the List Function is working correctly or not for NFT721 created", async () => {
          await mP.connect(owner).listItem(mNFT721.address, 1, false, 20, [], false, 10**10, { value: ethers.utils.parseEther("0.00000001") });
          expect(await mNFT721.connect(owner).balanceOf(mP.address)).to.be.equal(1);
        })

        it("Checks the Buy Function is working correctly or not for NFT721 listed", async () => {
          await mP.connect(signertwo).buyItem(1, { value: ethers.utils.parseEther("0.00000001") });
          expect(await mNFT721.connect(owner).balanceOf(signertwo.address)).to.be.equal(1);
        })

    })

  })