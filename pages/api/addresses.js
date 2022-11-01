export default function handler(req, res) {
  const network = req.query.network
  console.log('network', network)
  res.status(200).json({
    marketplaceAddress: process.env[`MARKETPLACE_${network}`],
    collectionAddress: process.env[`COLLECTION_${network}`]
  })
}
