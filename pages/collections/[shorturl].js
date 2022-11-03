import { LinearProgress } from '@mui/material'
import { useRouter } from 'next/router'
import { useContext, useEffect, useState, useRef } from 'react'
import { Web3Context } from '../../src/components/providers/Web3Provider'
import { fetchCollectionByShorturl, mapCollection } from '../../src/utils/collection'

import InstallMetamask from '../../src/components/molecules/InstallMetamask'
import NFTCardList from '../../src/components/organisms/NFTCardList'
import { mapCreatedAndOwnedTokenIdsAsMarketItems, getUniqueOwnedAndCreatedTokenIds, getNftContract } from '../../src/utils/nft'
import UnsupportedChain from '../../src/components/molecules/UnsupportedChain'
import ConnectWalletMessage from '../../src/components/molecules/ConnectWalletMessage'

// taken from https://usehooks.com/usePrevious/
function usePrevious (value) {
  const ref = useRef()

  useEffect(() => {
    ref.current = value
  }, [value])

  return ref.current
}

function useEffectAllDepsChange (fn, deps) {
  const prevDeps = usePrevious(deps)
  const changeTarget = useRef()

  useEffect(() => {
    // nothing to compare to yet
    if (changeTarget.current === undefined) {
      changeTarget.current = prevDeps
    }

    // we're mounting, so call the callback
    if (changeTarget.current === undefined) {
      return fn()
    }

    // make sure every dependency has changed
    if (changeTarget.current.every((dep, i) => dep !== deps[i])) {
      changeTarget.current = deps

      return fn()
    }
  }, [fn, prevDeps, deps])
}

const CollectionPage = () => {
  const [collectionData, setCollectionData] = useState(undefined)
  const [nfts, setNfts] = useState([])
  const { account, marketplaceContract, collectionContract, isReady, hasWeb3, network, providerSigner } = useContext(Web3Context)
  const [isLoading, setIsLoading] = useState(true)
  const [hasWindowEthereum, setHasWindowEthereum] = useState(false)
  const [nftContract, setNftContract] = useState(null)
  const [nfttype, setNfttype] = useState(0)

  const router = useRouter()
  const { shorturl } = router.query

  useEffect(() => {
    setHasWindowEthereum(window.ethereum)
  }, [])

  useEffectAllDepsChange(() => {
    if (nftContract && collectionData !== undefined) {
      console.log('running effect', [nftContract?.address, collectionData])
      loadNFTs()
    }
  }, [nftContract?.address, collectionData])

  // useEffect(() => {
  //     console.log('nftContract', nftContract)
  //     console.log('collectionId', collectionId)
  //     if (nftContract && collectionId !== undefined) {
  //         loadNFTs()
  //     }
  // }, [nftContract?.address, collectionId, isReady])

  useEffect(() => {
    if (isReady) {
      loadNftContract()
    }
  }, [account, isReady])

  async function loadNftContract () {
    console.log('loadNftContract isReady', isReady, hasWeb3)
    if (!isReady || !hasWeb3) return <></>
    console.log('shorturl', shorturl)

    const [collectionData, hasFound] = await fetchCollectionByShorturl(collectionContract, shorturl)
    if (hasFound) {
      console.log('collectionData', collectionData)
      setCollectionData(collectionData)

      const nftContract = await getNftContract(collectionData.nftType, collectionData.nftAddress, providerSigner)
      setNftContract(nftContract)
      // setNftAddress(collectionData.nftContract)
    }
  }

  async function loadNFTs () {
    // console.log('isReady', isReady, hasWeb3)
    // if (!isReady || !hasWeb3) {
    //     setIsLoading(false)
    //     return <></>
    // }
    console.log('dynamic nfttype', nfttype)
    console.log('dynamic nftContract2', nftContract)
    console.log('dynamic collectionData', collectionData)
    const myUniqueCreatedAndOwnedTokenIds = await getUniqueOwnedAndCreatedTokenIds(nftContract)
    console.log('myUniqueCreatedAndOwnedTokenIds', myUniqueCreatedAndOwnedTokenIds)

    const myNfts = await Promise.all(myUniqueCreatedAndOwnedTokenIds.map(
      mapCreatedAndOwnedTokenIdsAsMarketItems(marketplaceContract, collectionData.collectionId, nftContract, account)
    ))
    console.log('myNfts', myNfts)
    setNfts(myNfts)
    setIsLoading(false)
  }

  if (!hasWindowEthereum) return <InstallMetamask />
  if (!hasWeb3) return <ConnectWalletMessage />
  if (!network) return <UnsupportedChain />
  if (isLoading) return <LinearProgress />

  return (
    <NFTCardList collectionData={collectionData} nftContract={nftContract} nfts={nfts} setNfts={setNfts} withCreateNFT={true} />
  )
}

export default CollectionPage
