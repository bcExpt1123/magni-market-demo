import InfiniteScroll from 'react-infinite-scroll-component'
import Grid from '@mui/material/Grid'
import LinearProgress from '@mui/material/LinearProgress'
import Fade from '@mui/material/Fade'
import { makeStyles } from '@mui/styles'
import CollectionCard from '../molecules/CollectionCard'
import CollectionCardCreation from '../molecules/CollectionCardCreation'
import { ethers } from 'ethers'
import { Web3Context } from '../providers/Web3Provider'
import { useContext } from 'react'
import { mapCollections } from '../../utils/collection'

const useStyles = makeStyles((theme) => ({
  grid: {
    spacing: 3,
    alignItems: 'stretch'
  },
  gridItem: {
    display: 'flex',
    transition: 'all .3s',
    [theme.breakpoints.down('sm')]: {
      margin: '0 20px'
    }
  }
}))

export default function CollectionCardList({ collections, setCollections, withCreateCollection }) {
  const classes = useStyles()
  const { account, collectionContract } = useContext(Web3Context)

  async function addCollectionToList(collectionId) {
    const collection = await mapCollections(collectionContract)(collectionId)
    setCollections(prevCollections => [collection, ...prevCollections])
  }

  function Collection({ collection, index }) {
    if (!collection.creator) {
      return <CollectionCardCreation addCollectionToList={addCollectionToList} />
    }

    return <CollectionCard collection={collection} />
  }

  return (
    <InfiniteScroll
      dataLength={collections.length}
      loader={<LinearProgress />}
    >
      <Grid container className={classes.grid} id="grid">
        {withCreateCollection && <Grid item xs={12} sm={6} md={3} className={classes.gridItem}>
          <CollectionCardCreation addCollectionToList={addCollectionToList} />
        </Grid>}
        {collections.map((collection, i) =>
          <Fade in={true} key={i}>
            <Grid item xs={12} sm={6} md={3} className={classes.gridItem} >
              <Collection collection={collection} index={i} />
            </Grid>
          </Fade>
        )}
      </Grid>
    </InfiniteScroll>
  )
}
