// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const MarketPlace = await ethers.getContractFactory("MarketPlace");
  const marketPlace = await MarketPlace.deploy();
  await marketPlace.deployed();
  console.log("MarketPlace deployed to:", marketPlace.address);

  const MarketPlacewithAutobid = await ethers.getContractFactory(
    "MarketPlacewithAutobid"
  );
  const marketPlacewithAutobid = await MarketPlacewithAutobid.deploy();
  await marketPlacewithAutobid.deployed();
  console.log(
    "MarketPlacewithAutobid deployed to:",
    marketPlacewithAutobid.address
  );

  const MNFT1155 = await ethers.getContractFactory("MNFT1155");
  const mNFT1155 = await MNFT1155.deploy();
  await mNFT1155.deployed();
  console.log("MNFT1155 deployed to:", mNFT1155.address);

  const MNFT721 = await ethers.getContractFactory("MNFT721");
  const mNFT721 = await MNFT721.deploy();
  await mNFT721.deployed();
  console.log("MNFT721 deployed to:", mNFT721.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
