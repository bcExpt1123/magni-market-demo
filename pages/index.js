import { useContext, useEffect, useState } from 'react'
import NFTCardList from '../src/components/organisms/NFTCardList'
import { Web3Context } from '../src/components/providers/Web3Provider'
import { LinearProgress } from '@mui/material'
import UnsupportedChain from '../src/components/molecules/UnsupportedChain'
import { mapAvailableMarketItems } from '../src/utils/nft'

export default function Home () {
  const [nfts, setNfts] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const { marketplaceContract, isReady, network, providerSigner } = useContext(Web3Context)

  useEffect(() => {
    loadNFTs()
  }, [isReady])
  async function loadNFTs () {
    if (!isReady) return
    const [data, hasFound, counts] = await marketplaceContract.fetchMarketItems()
    console.log('hasFound fetchMarketItems', hasFound, counts)
    if (hasFound) {
      const items = await Promise.all(data.map(mapAvailableMarketItems(providerSigner)))
      setNfts(items)
    }
    setIsLoading(false)
  }

  if (!network) return <UnsupportedChain />
  if (isLoading) return <LinearProgress />
  if (!isLoading && !nfts.length) return <h1>No NFTs for sale</h1>
  return (
    <NFTCardList nfts={nfts} setNfts={setNfts} withCreateNFT={false} />
  )
}
