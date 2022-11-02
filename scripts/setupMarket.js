const hre = require('hardhat')

const zombieCollectionMetadataUrl = "https://ipfs.io/ipfs/QmNyzmjaJ8E8BF4vNWXiJZjEM5ASoFPmrhdoShSYnEdXHQ"
const portfolioCollectionMetadataUrl = "https://ipfs.io/ipfs/QmNyzmjaJ8E8BF4vNWXiJZjEM5ASoFPmrhdoShSYnEdXHQ"

const dogsMetadataUrl = 'https://ipfs.io/ipfs/Qma1wY9HLfdWbRr1tDPpVCfbtPPvjnai1rEukuqSxk6PWb'
const techEventMetadataUrl = 'https://ipfs.io/ipfs/QmchRqWmRiHP2uXBGxT7sJJUJChDddHpyApoH94S3VkH42'
const yellowCrownMetadataUrl = 'https://ipfs.io/ipfs/QmVXBCJcDtgtZfx77W86iG5hrJnFjWz1HV7naHAJMArqNT'
const ashleyMetadataUrl = 'https://ipfs.io/ipfs/QmdiA6eywkjMAVGTYRXerSQozLEBA3QpKmAt1E1mKVovhz'
const codeconMetadataUrl = 'https://ipfs.io/ipfs/QmdMbGwGLmC5iNmv1hzRvJQpzrKmKfHjbB34k4e8AfqKay'
const webArMetadataUrl = 'https://ipfs.io/ipfs/QmSzFfx3rNqdJwSsrFpfMcxZCncaATsCceaFEr6Lmq3VUz'

async function getCreatedCollection (transaction) {
  const transactionResult = await transaction.wait()
  const event = transactionResult.events[0]
  const value = event.args[0]
  return [value.toNumber(), event.args[2]]
}

async function getMintedTokenId (transaction) {
  const transactionResult = await transaction.wait()
  // console.log('NFT transactionResult', transactionResult)
  const events = transactionResult.events
  // console.log('NFT mint', events)
  const event = transactionResult.events[1]
  const value = event.args[0]
  return value.toNumber()
}

async function getCreatedMarketItemId (transaction) {
  const transactionResult = await transaction.wait()
  // console.log('MarketItem transactionResult', transactionResult.events)
  const marketItemEvent = transactionResult.events.find(event => event.args)
  const value = marketItemEvent.args[1]
  return value.toNumber()
}

async function setupMarket (marketplaceAddress, erc20Address, royaltyAddress, collectionAddress) {
  const [acc1, acc2] = await hre.ethers.getSigners()
  console.log('acc1', acc1.address)
  console.log('acc2', acc2.address)
  const networkName = hre.network.name.toUpperCase()
  console.log('networkName', networkName)



  marketplaceAddress = marketplaceAddress || process.env[`MARKETPLACE_${networkName}`]
  erc20Address = erc20Address || process.env[`THOR_V2_${networkName}`]
  royaltyAddress = royaltyAddress || process.env[`ROYALTY_${networkName}`]
  collectionAddress = collectionAddress || process.env[`COLLECTION_${networkName}`]

  const collectionContract = await hre.ethers.getContractAt('CollectionManager', collectionAddress)
  let sampleShorturl = "zombiemonkeys"
  let sampleShorturl2 = "portfolio"
  const [collection, hasFound] = await collectionContract.fetchCollectionByShorturl(sampleShorturl)
  console.log('hasFound', hasFound)

  if (!hasFound) {
    const createCollectionTx = await collectionContract.createCollection(0, "Zombie Monkeys", "ZmBM", sampleShorturl, zombieCollectionMetadataUrl) // ERC721 collection, collectionId = 0
    const [collectionId, nftAddress] = await getCreatedCollection(createCollectionTx)
    console.log('collectionId', collectionId, nftAddress)

    const marketplaceContract = await hre.ethers.getContractAt('Marketplace', marketplaceAddress)
    const nftContract = await hre.ethers.getContractAt('MockERC721', nftAddress)

    const price = hre.ethers.utils.parseEther('0.01')
    const listingFee = await marketplaceContract.getListingFee()

    const dogsMintTx = await collectionContract.createNFT(collectionId, acc1.address, dogsMetadataUrl, 0)
    const dogsTokenId = await getMintedTokenId(dogsMintTx)
    console.log('dogsTokenId', dogsTokenId)

    const techEventMintTx = await collectionContract.createNFT(collectionId, acc1.address, techEventMetadataUrl, 0)
    const techEventTokenId = await getMintedTokenId(techEventMintTx)
    const codeconMintTx = await collectionContract.createNFT(collectionId, acc1.address, codeconMetadataUrl, 0)
    const codeconTokenId = await getMintedTokenId(codeconMintTx)
    const webArMintTx = await collectionContract.createNFT(collectionId, acc1.address, webArMetadataUrl, 0)
    const webArTokenId = await getMintedTokenId(webArMintTx)
    // uint8 nftType,
    //   address nftContract,
    //     uint256 collectionId,
    //       uint256 tokenId,
    //         uint8 paymentMethod,
    //           uint256 price,
    //             uint256 amountOfErc1155

    await nftContract.approve(marketplaceAddress, dogsTokenId)
    const dogsMarketTx = await marketplaceContract.createMarketItem(0, nftAddress, collectionId, dogsTokenId, 0, price, 0, { value: listingFee })
    const dogsMarketItemId = await getCreatedMarketItemId(dogsMarketTx)
    await nftContract.approve(marketplaceAddress, techEventTokenId)
    await marketplaceContract.createMarketItem(0, nftAddress, collectionId, techEventTokenId, 0, price, 0, { value: listingFee })
    await nftContract.approve(marketplaceAddress, codeconTokenId)
    const codeconMarketTx = await marketplaceContract.createMarketItem(0, nftAddress, collectionId, codeconTokenId, 0, price, 0, { value: listingFee })
    const codeconMarketItemId = await getCreatedMarketItemId(codeconMarketTx)
    await nftContract.approve(marketplaceAddress, webArTokenId)
    const webArMarketTx = await marketplaceContract.createMarketItem(0, nftAddress, collectionId, webArTokenId, 0, price, 0, { value: listingFee })
    const webArMarketItemId = await getCreatedMarketItemId(webArMarketTx)
    console.log(`${acc1.address} minted tokens ${dogsTokenId}, ${techEventTokenId}, ${codeconTokenId} and ${webArTokenId} and listed them as market items`)

    await marketplaceContract.cancelMarketItem(codeconMarketItemId)
    console.log(`${acc1.address} canceled market item for token ${codeconTokenId}`)


    const createCollectionTx2 = await collectionContract.connect(acc2).createCollection(0, "Portfolio", "PoM", sampleShorturl2, portfolioCollectionMetadataUrl) // ERC721 collection, collectionId = 0
    const [collectionId2, nftAddress2] = await getCreatedCollection(createCollectionTx2)
    console.log('collectionId2', collectionId2, nftAddress2)

    const nftContract2 = await hre.ethers.getContractAt('MockERC721', nftAddress2)

    const yellowMintTx = await collectionContract.connect(acc2).createNFT(collectionId2, acc2.address, yellowCrownMetadataUrl, 0)
    const yellowTokenId = await getMintedTokenId(yellowMintTx)
    console.log('yellowTokenId', yellowTokenId)

    const ashleyMintTx = await collectionContract.connect(acc2).createNFT(collectionId2, acc2.address, ashleyMetadataUrl, 0)
    const ashleyTokenId = await getMintedTokenId(ashleyMintTx)
    await nftContract2.connect(acc2).approve(marketplaceAddress, yellowTokenId)
    const yellowMarketTx = await marketplaceContract.connect(acc2).createMarketItem(0, nftAddress2, collectionId2, yellowTokenId, 0, price, 0, { value: listingFee })
    const yellowMarketItemId = await getCreatedMarketItemId(yellowMarketTx)
    await nftContract2.connect(acc2).approve(marketplaceAddress, ashleyTokenId)
    const ashleyMarketTx = await marketplaceContract.connect(acc2).createMarketItem(0, nftAddress2, collectionId2, ashleyTokenId, 0, price, 0, { value: listingFee })
    const ashleyMarketItemId = await getCreatedMarketItemId(ashleyMarketTx)
    console.log(`${acc2.address} minted tokens ${yellowTokenId} and ${ashleyTokenId} and listed them as market items`)


    await marketplaceContract.createMarketSale(yellowMarketItemId, 0, { value: price })
    console.log(`${acc1.address} bought token ${yellowTokenId}`)
    await nftContract2.connect(acc1).approve(marketplaceAddress, yellowTokenId)
    await marketplaceContract.createMarketItem(0, nftAddress2, collectionId2, yellowTokenId, 0, price, 0, { value: listingFee })
    console.log(`${acc1.address} put token ${yellowTokenId} for sale`)

    await marketplaceContract.connect(acc2).createMarketSale(dogsMarketItemId, 0, { value: price })
    await nftContract.connect(acc2).approve(marketplaceAddress, dogsTokenId)
    await marketplaceContract.connect(acc2).createMarketItem(0, nftAddress, collectionId, dogsTokenId, 0, price, 0, { value: listingFee })
    console.log(`${acc2.address} bought token ${dogsTokenId} and put it for sale`)

    await marketplaceContract.connect(acc2).createMarketSale(webArMarketItemId, 0, { value: price })
    console.log(`${acc2.address} bought token ${webArTokenId}`)
  }
}

async function main () {
  if (process.env.IS_RUNNING) return
  await setupMarket()
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })

module.exports = {
  setupMarket: setupMarket
}
