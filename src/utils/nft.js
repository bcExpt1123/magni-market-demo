import axios from 'axios'
import { ethers } from 'ethers'
import MockERC721 from '../../artifacts/contracts/mock/MockERC721.sol/MockERC721.json'

export async function getNftContract (nftAddress, providerSigner) {
  try {
    console.log('nftAddress', nftAddress)
    console.log('providerSigner', providerSigner)
    const nftContract = new ethers.Contract(nftAddress, MockERC721.abi, providerSigner)
    console.log('nftContract', nftContract)
    return nftContract
  } catch (error) {
    console.log(error)
  }
}

export async function getTokenMetadataByTokenId (nftContract, tokenId) {
  try {
    console.log('tokenId', tokenId, nftContract)
    const tokenUri = await nftContract.tokenURI(tokenId)
    const { data: metadata } = await axios.get(tokenUri)
    return metadata
  } catch (error) {
    console.log(error)
  }
}

export function mapAvailableMarketItems (providerSigner) {
  return async (marketItem) => {
    console.log('marketItem', marketItem)
    console.log('nftAddress', marketItem.nftAddress)
    const nftContract = await getNftContract(marketItem.nftAddress, providerSigner)

    const metadata = await getTokenMetadataByTokenId(nftContract, marketItem.tokenId)
    return mapMarketItem(marketItem, metadata)
  }
}

export function mapCreatedAndOwnedTokenIdsAsMarketItems (marketplaceContract, collectionId, nftContract, account) {
  return async (tokenId) => {
    console.log('nftContract', collectionId, tokenId, nftContract)
    const metadata = await getTokenMetadataByTokenId(nftContract, tokenId)
    const approveAddress = await nftContract.getApproved(tokenId)
    const hasMarketApproval = approveAddress === marketplaceContract.address
    const [foundMarketItem, hasFound] = await marketplaceContract.getLatestMarketItemByTokenId(collectionId, tokenId)
    console.log('hasFound', collectionId, tokenId, hasFound)
    const marketItem = hasFound ? foundMarketItem : {}
    return mapMarketItem(marketItem, metadata, tokenId, account, hasMarketApproval)
  }
}

export function mapMarketItem (marketItem, metadata, tokenId, account, hasMarketApproval) {
  return {
    price: marketItem.price ? ethers.utils.formatUnits(marketItem.price, 'ether') : undefined,
    collectionId: marketItem.collectionId,
    nftAddress: marketItem.nftAddress,
    tokenId: marketItem.tokenId || tokenId,
    marketItemId: marketItem.marketItemId || undefined,
    creator: marketItem.creator || account,
    seller: marketItem.seller || undefined,
    owner: marketItem.owner || account,
    sold: marketItem.sold || false,
    canceled: marketItem.canceled || false,
    image: metadata.image,
    name: metadata.name,
    description: metadata.description,
    hasMarketApproval: hasMarketApproval || false
  }
}

export async function getUniqueOwnedAndCreatedTokenIds (nftContract) {
  const nftIdsCreatedByMe = await nftContract.getTokensCreatedByMe()
  const nftIdsOwnedByMe = await nftContract.getTokensOwnedByMe()
  const myNftIds = [...nftIdsCreatedByMe, ...nftIdsOwnedByMe]
  console.log('myNftIds', myNftIds)
  const tt = [...new Map(myNftIds.map((item) => [item._hex, item])).values()]
  console.log('tt', tt)
  return tt
}
