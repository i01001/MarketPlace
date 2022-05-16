import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import "@nomiclabs/hardhat-web3";
import { ethers } from "hardhat";

import "./accounts.ts";
import "./mint.ts";
