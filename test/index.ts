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
        it("Checks thesetNFT721ContractAddress is updated correctly or not", async () => {
          await mP.setNFT721ContractAddress(mNFT721.address);
            expect(await mP.NFT721Contract()).to.be.equal(await mNFT721.address);
        })
    })

  })