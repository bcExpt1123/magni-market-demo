import { LinearProgress } from '@mui/material'
import { useContext, useEffect, useState } from 'react'
import InstallMetamask from '../src/components/molecules/InstallMetamask'
import CollectionCardList from '../src/components/organisms/CollectionCardList'
import { Web3Context } from '../src/components/providers/Web3Provider'
import { mapCollections, fetchMyCollectionIds } from '../src/utils/collection'
import UnsupportedChain from '../src/components/molecules/UnsupportedChain'
import ConnectWalletMessage from '../src/components/molecules/ConnectWalletMessage'

export default function CreatorCollection () {
  const [collections, setCollections] = useState([])
  const { account, marketplaceContract, collectionContract, nftContract, isReady, hasWeb3, network } = useContext(Web3Context)
  const [isLoading, setIsLoading] = useState(true)
  const [hasWindowEthereum, setHasWindowEthereum] = useState(false)

  useEffect(() => {
    setHasWindowEthereum(window.ethereum)
  }, [])

  useEffect(() => {
    loadCollections()
  }, [account, isReady])

  async function loadCollections () {
    if (!isReady || !hasWeb3) return <></>
    const myCollectionIds = await fetchMyCollectionIds(collectionContract)
    const mapMyCollections = await Promise.all(myCollectionIds.map(
      mapCollections(collectionContract)
    ))
    console.log('mapMyCollections', mapMyCollections)
    setCollections(mapMyCollections)
    setIsLoading(false)
  }

  if (!hasWindowEthereum) return <InstallMetamask />
  if (!hasWeb3) return <ConnectWalletMessage />
  if (!network) return <UnsupportedChain />
  if (isLoading) return <LinearProgress />

  return (
    <CollectionCardList collections={collections} setCollections={setCollections} withCreateCollection={true} />
  )
}
