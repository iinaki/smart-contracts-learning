// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require('hardhat');

const hre = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether')
}

async function main() {
  let [buyer, seller, inspector, lender] = await ethers.getSigners()

  const RealEstate = await ethers.getContractFactory('RealEstate')
  realEstate = await RealEstate.deploy()
  await realEstate.deployed()
  console.log("RealEstate deployed to:", realEstate.address)
  console.log("minting 3 properties...")

  for(let i = 0; i < 3; i++){
    let transaction = await realEstate.connect(seller).mint(`https://ipfs.io/ipfs/QmQVcpsjrA6cr1iJjZAodYwmPekYgbnXGo4DFubJiLc2EB/${i + 1}.json`)
    await transaction.wait()
  }

  const Escrow = await ethers.getContractFactory('Escrow')
  escrow = await Escrow.deploy(
    realEstate.address,
    seller.address,
    inspector.address,
    lender.address
  )
  await escrow.deployed()

  for(let i = 0; i < 3; i++){
    let transaction = await realEstate.connect(seller).approve(escrow.address, i + 1)
    await transaction.wait()
  }

  transaction = await escrow.connect(seller).list(1,tokens(20),tokens(10), buyer.address)
  await transaction.wait()

  transaction = await escrow.connect(seller).list(2,tokens(15),tokens(5), buyer.address)
  await transaction.wait()

  transaction = await escrow.connect(seller).list(3,tokens(10),tokens(5), buyer.address)
  await transaction.wait()

  console.log("FINISHED")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
