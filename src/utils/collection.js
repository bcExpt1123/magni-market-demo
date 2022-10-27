import axios from 'axios'
import { ethers } from 'ethers'

export async function getCollectionMetadataByCollectionId(collectionContract, collectionId) {
  try {
    const collectionUri = await collectionContract.collectionURI(collectionId)
    console.log('collectionUri', collectionUri)
    const { data: metadata } = await axios.get(collectionUri)
    return metadata
  } catch (error) {
    console.log(error)
  }
}

export function mapCollections(collectionContract, account) {
  return async (collectionId) => {
    console.log('collectionId', collectionId)
    const metadata = await getCollectionMetadataByCollectionId(collectionContract, collectionId)
    return mapCollection(metadata, account)
  }
}

export function mapCollection(metadata, account) {
  return {
    creator: account,
    image: metadata.image,
    name: metadata.name,
    description: metadata.description,
  }
}

export async function fetchMyCollectionIds(collectionContract) {
  const myCollections = await collectionContract.fetchMyCollectionIds()
  // const myCollectionIds = [...myCollections]
  return myCollections
  // return [...new Map(myCollections.map((item) => [item._hex, item])).values()]
}
