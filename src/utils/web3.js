export function getProvider () {
  if (typeof window !== 'undefined' && typeof window.ethereum !== 'undefined') {
    if (window.ethereum.isMetaMask) return 'Metamask'
    if (window.ethereum.isImToken) return 'imToken'
  }
  return 'Wallet'
}

export const chains = {
  polygonMumbaiTestnet: {
    name: 'Polygon Testnet Mumbai',
    chain: 'Polygon',
    rpc: [
      'https://matic-mumbai.chainstacklabs.com',
      'https://rpc-mumbai.maticvigil.com',
      'https://matic-testnet-archive-rpc.bwarelabs.com'
    ],
    faucets: [
      'https://faucet.polygon.technology/'
    ],
    nativeCurrency: {
      name: 'MATIC',
      symbol: 'MATIC',
      decimals: 18
    },
    infoURL: 'https://polygon.technology/',
    shortName: 'maticmum',
    chainId: 80001,
    networkId: 80001,
    explorers: [{
      name: 'polygonscan',
      url: 'https://mumbai.polygonscan.com',
      standard: 'EIP3091'
    }]
  },
  avalancheFujiTestnet: {
    name: 'Avalanche Fuji Testnet',
    chain: 'Avalanche',
    rpc: [
      'https://api.avax-test.network/ext/bc/C/rpc',
    ],
    faucets: [
    ],
    nativeCurrency: {
      name: 'AVAX',
      symbol: 'AVAX',
      decimals: 18
    },
    infoURL: '',
    shortName: 'fuji',
    chainId: 43113,
    networkId: 43113,
    explorers: [{
      name: 'snowtrace',
      url: 'https://testnet.snowtrace.com',
      standard: 'EIP3091'
    }]
  }
}
