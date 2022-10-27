
import { ethers } from 'ethers'
import { useContext, useEffect, useState } from 'react'
import { makeStyles } from '@mui/styles'
import { Card, CardActions, CardContent, CardMedia, Button, Divider, Box, CircularProgress } from '@mui/material'
import { CollectionModalContext } from '../providers/CollectionModalProvider'
import { Web3Context } from '../providers/Web3Provider'
import CollectionDescription from '../atoms/CollectionDescription'
import CollectionName from '../atoms/CollectionName'
import CardAddresses from './CardAddresses'
import PriceTextField from '../atoms/PriceTextField'

const useStyles = makeStyles({
  root: {
    flexDirection: 'column',
    display: 'flex',
    margin: '15px',
    flexGrow: 1,
    maxWidth: 345
  },
  media: {
    height: 0,
    paddingTop: '86.25%', // 16:9
    cursor: 'pointer'
  },
  cardContent: {
    paddingBottom: '8px',
    display: 'flex',
    flexDirection: 'column',
    height: '100%'
  },
  firstDivider: {
    margin: 'auto 0 10px'
  },
  lastDivider: {
    marginTop: '10px'
  },
  addressesAndPrice: {
    display: 'flex',
    flexDirection: 'row'
  },
  addessesContainer: {
    margin: 'auto',
    width: '60%'
  },
  priceContainer: {
    width: '40%',
    margin: 'auto'
  },
  cardActions: {
    marginTop: 'auto',
    padding: '0 16px 8px 16px'
  }
})

async function getAndSetListingFee(marketplaceContract, setListingFee) {
  if (!marketplaceContract) return
  const listingFee = await marketplaceContract.getListingFee()
  setListingFee(ethers.utils.formatUnits(listingFee, 'ether'))
}

export default function CollectionCard({ collection, updateCollection }) {
  const { setModalCollection, setIsModalOpen } = useContext(CollectionModalContext)
  const { collectionContract, marketplaceContract, hasWeb3 } = useContext(Web3Context)
  const [isHovered, setIsHovered] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [listingFee, setListingFee] = useState('')
  const [priceError, setPriceError] = useState(false)
  const [newPrice, setPrice] = useState(0)
  const classes = useStyles()
  const { name, description, image } = collection

  useEffect(() => {
    getAndSetListingFee(marketplaceContract, setListingFee)
  }, [])

  function handleCardImageClick() {
    setModalCollection(collection)
    setIsModalOpen(true)
  }

  async function onClick(collection) {
    try {
      setIsLoading(true)
    } catch (error) {
      console.log(error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Card
      className={classes.root}
      raised={isHovered}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <CardMedia
        className={classes.media}
        alt={name}
        image={image}
        component="a" onClick={handleCardImageClick}
      />

      <CardContent className={classes.cardContent} >
        <CollectionName name={name} />
        <CollectionDescription description={description} />
      </CardContent>
    </Card>
  )
}
