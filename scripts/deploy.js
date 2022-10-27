const hre = require('hardhat')
const dotenv = require('dotenv')
const fs = require('fs')

function replaceEnvContractAddresses (marketplaceAddress, collectionAddress, nftAddress, networkName) {
  const envFileName = '.env.local'
  const envFile = fs.readFileSync(envFileName, 'utf-8')
  const env = dotenv.parse(envFile)
  env[`MARKETPLACE_CONTRACT_ADDRESS_${networkName}`] = marketplaceAddress
  env[`COLLECTION_CONTRACT_ADDRESS_${networkName}`] = collectionAddress
  env[`NFT_CONTRACT_ADDRESS_${networkName}`] = nftAddress
  const newEnv = Object.entries(env).reduce((env, [key, value]) => {
    return `${env}${key}=${value}\n`
  }, '')

  fs.writeFileSync(envFileName, newEnv)
}

async function main () {
  process.env.IS_RUNNING = true
  const Marketplace = await hre.ethers.getContractFactory('Marketplace')
  const marketplace = await Marketplace.deploy()
  await marketplace.deployed()
  console.log('Marketplace deployed to:', marketplace.address)

  const CollectionManager = await hre.ethers.getContractFactory('CollectionManager')
  const collectionManager = await CollectionManager.deploy()
  await collectionManager.deployed()
  console.log('collectionManager deployed to:', collectionManager.address)

  const NFT = await hre.ethers.getContractFactory('NFT')
  const nft = await NFT.deploy(marketplace.address)
  await nft.deployed()
  console.log('Nft deployed to:', nft.address)

  replaceEnvContractAddresses(marketplace.address, collectionManager.address, nft.address, hre.network.name.toUpperCase())
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
