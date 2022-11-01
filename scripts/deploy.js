const hre = require('hardhat')
const dotenv = require('dotenv')
const fs = require('fs')

function replaceEnvContractAddresses(marketplaceAddress, erc20Address, royaltyAddress, collectionAddress, networkName) {
  const envFileName = '.env.local'
  const envFile = fs.readFileSync(envFileName, 'utf-8')
  const env = dotenv.parse(envFile)
  env[`MARKETPLACE_${networkName}`] = marketplaceAddress
  env[`THOR_V2_${networkName}`] = erc20Address
  env[`ROYALTY_${networkName}`] = royaltyAddress
  env[`COLLECTION_${networkName}`] = collectionAddress
  const newEnv = Object.entries(env).reduce((env, [key, value]) => {
    return `${env}${key}=${value}\n`
  }, '')

  fs.writeFileSync(envFileName, newEnv)
}

async function main() {
  process.env.IS_RUNNING = true


  const CollectionManager = await hre.ethers.getContractFactory('CollectionManager')
  const collectionManager = await CollectionManager.deploy()
  await collectionManager.deployed()
  console.log('collectionManager deployed to:', collectionManager.address)

  const RoyaltyManager = await hre.ethers.getContractFactory("RoyaltyManager")
  const royalty = await RoyaltyManager.deploy()
  await royalty.deployed()
  console.log("royalty deployed to:", royalty.address)

  // tried ERC20 token instead of ThorV2 for simplicity
  const ERC20 = await hre.ethers.getContractFactory('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20')
  const erc20 = await ERC20.deploy('thorV2', 'tv2')
  await erc20.deployed()
  console.log('erc20 deployed to:', erc20.address)

  const Marketplace = await hre.ethers.getContractFactory('Marketplace')
  const marketplace = await Marketplace.deploy(erc20.address, royalty.address, collectionManager.address)
  await marketplace.deployed()
  console.log('Marketplace deployed to:', marketplace.address)

  // const NFT = await hre.ethers.getContractFactory('NFT')
  // const nft = await NFT.deploy(marketplace.address)
  // await nft.deployed()
  // console.log('Nft deployed to:', nft.address)

  replaceEnvContractAddresses(marketplace.address, erc20.address, royalty.address, collectionManager.address, hre.network.name.toUpperCase())
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
