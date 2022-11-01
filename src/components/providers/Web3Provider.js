import { createContext, useEffect, useState } from 'react'
import Web3Modal from 'web3modal'
import { ethers } from 'ethers'
import MockERC721 from '../../../artifacts/contracts/mock/MockERC721.sol/MockERC721.json'
import Market from '../../../artifacts/contracts/mock/Marketplace.sol/Marketplace.json'
import Collection from '../../../artifacts/contracts/mock/CollectionManager.sol/CollectionManager.json'
import axios from 'axios'

const contextDefaultValues = {
  account: '',
  network: 'maticmum',
  balance: 0,
  connectWallet: () => { },
  marketplaceContract: null,
  collectionContract: null,
  nftContract: null,
  isReady: false,
  hasWeb3: false
}

const networkNames = {
  maticmum: 'MUMBAI',
  fuji: 'FUJI',
  unknown: 'LOCALHOST'
}

export const Web3Context = createContext(
  contextDefaultValues
)

export default function Web3Provider({ children }) {
  const [hasWeb3, setHasWeb3] = useState(contextDefaultValues.hasWeb3)
  const [account, setAccount] = useState(contextDefaultValues.account)
  const [network, setNetwork] = useState(contextDefaultValues.network)
  const [balance, setBalance] = useState(contextDefaultValues.balance)
  const [marketplaceContract, setMarketplaceContract] = useState(contextDefaultValues.marketplaceContract)
  const [collectionContract, setCollectionContract] = useState(contextDefaultValues.collectionContract)
  const [nftContract, setNftContract] = useState(contextDefaultValues.nftContract)
  const [isReady, setIsReady] = useState(contextDefaultValues.isReady)
  const [nftAddress, setNftAddress] = useState('')

  useEffect(() => {
    initializeWeb3()
  }, [])

  useEffect(async () => {
    if (nftAddress) {
      console.log("changed nftAddress")
      initializeWeb3()
    }
  }, [nftAddress])

  async function initializeWeb3WithoutSigner() {
    console.log('initializeWeb3WithoutSigner')
    const alchemyProvider = new ethers.providers.AlchemyProvider(80001)
    setHasWeb3(false)
    await getAndSetWeb3ContextWithoutSigner(alchemyProvider)
  }

  async function initializeWeb3() {
    console.log('initializeWeb3')
    try {
      if (!window.ethereum) {
        console.log('!window.ethereum')
        await initializeWeb3WithoutSigner()
        return
      }

      let onAccountsChangedCooldown = false
      const web3Modal = new Web3Modal()
      const connection = await web3Modal.connect()
      setHasWeb3(true)
      const provider = new ethers.providers.Web3Provider(connection, 'any')
      await getAndSetWeb3ContextWithSigner(provider)

      function onAccountsChanged(accounts) {
        // Workaround to accountsChanged metamask mobile bug
        if (onAccountsChangedCooldown) return
        onAccountsChangedCooldown = true
        setTimeout(() => { onAccountsChangedCooldown = false }, 1000)
        const changedAddress = ethers.utils.getAddress(accounts[0])
        return getAndSetAccountAndBalance(provider, changedAddress)
      }

      connection.on('accountsChanged', onAccountsChanged)
      connection.on('chainChanged', initializeWeb3)
    } catch (error) {
      console.log('!window.ethereum error')
      initializeWeb3WithoutSigner()
      console.log(error)
    }
  }

  async function getAndSetWeb3ContextWithSigner(provider) {
    setIsReady(false)
    const signer = provider.getSigner()
    const signerAddress = await signer.getAddress()
    await getAndSetAccountAndBalance(provider, signerAddress)
    const networkName = await getAndSetNetwork(provider)
    const success = await setupContracts(signer, networkName)
    setIsReady(success)
  }

  async function getAndSetWeb3ContextWithoutSigner(provider) {
    setIsReady(false)
    const networkName = await getAndSetNetwork(provider)
    const success = await setupContracts(provider, networkName)
    setIsReady(success)
  }

  async function getAndSetAccountAndBalance(provider, address) {
    setAccount(address)
    const signerBalance = await provider.getBalance(address)
    const balanceInEther = ethers.utils.formatEther(signerBalance, 'ether')
    setBalance(balanceInEther)
  }

  async function getAndSetNetwork(provider) {
    let { name: network } = await provider.getNetwork()
    console.log('network', network)
    const { chainId: chainId } = await provider.getNetwork()
    if (chainId == 43113) network = 'fuji'
    console.log('network', network)

    const networkName = networkNames[network]
    setNetwork(networkName)
    return networkName
  }

  async function setupContracts(signer, networkName) {
    if (!networkName) {
      setMarketplaceContract(null)
      setCollectionContract(null)
      setNftContract(null)
      return false
    }

    const { data } = await axios(`/api/addresses?network=${networkName}`)
    const marketplaceContract = new ethers.Contract(data.marketplaceAddress, Market.abi, signer)
    setMarketplaceContract(marketplaceContract)
    const collectionContract = new ethers.Contract(data.collectionAddress, Collection.abi, signer)
    setCollectionContract(collectionContract)

    if (nftAddress) {
      const nftContract = new ethers.Contract(nftAddress, MockERC721.abi, signer)
      setNftContract(nftContract)
    }
    return true
  }

  return (
    <Web3Context.Provider
      value={{
        account,
        marketplaceContract,
        collectionContract,
        nftContract,
        isReady,
        network,
        balance,
        setNftAddress,
        initializeWeb3,
        hasWeb3
      }}
    >
      {children}
    </Web3Context.Provider>
  )
};
