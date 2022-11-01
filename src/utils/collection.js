import axios from 'axios'
import { ethers } from 'ethers'

export async function getCollectionMetadata(collectionUri) {
  try {
    const { data: metadata } = await axios.get(collectionUri)
    return metadata
  } catch (error) {
    console.log(error)
  }
}

export function mapCollections(collectionContract) {
  return async (collectionId) => {
    const collectionData = await collectionContract.fetchCollectionByCollectionId(collectionId)
    return mapCollection(collectionData)
  }
}

export async function mapCollection(collectionData) {
  const collectionUri = collectionData.uri
  const metadata = await getCollectionMetadata(collectionUri)
  return {
    name: collectionData.name,
    symbol: collectionData.symbol,
    shorturl: collectionData.shorturl,
    creator: collectionData.creator,
    image: metadata.image,
    description: metadata.description,
  }
}

export async function fetchMyCollectionIds(collectionContract) {
  const myCollections = await collectionContract.fetchMyCollectionIds()
  // const myCollectionIds = [...myCollections]
  return myCollections
  // return [...new Map(myCollections.map((item) => [item._hex, item])).values()]
}

export async function fetchCollectionByShorturl(collectionContract, shorturl) {
  const collectionData = await collectionContract.fetchCollectionByShorturl(shorturl)
  return collectionData
}
