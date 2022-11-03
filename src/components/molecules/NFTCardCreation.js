
import { useContext, useState } from 'react'
import { useForm } from 'react-hook-form'
import { makeStyles } from '@mui/styles'
import { TextField, Card, CardActions, CardContent, CardMedia, Button, CircularProgress } from '@mui/material'
import axios from 'axios'
import { Web3Context } from '../providers/Web3Provider'
import { getNftContract } from '../../utils/nft'

const useStyles = makeStyles({
  root: {
    flexDirection: 'column',
    display: 'flex',
    margin: '15px 15px',
    flexGrow: 1
  },
  cardActions: {
    marginTop: 'auto'
  },
  media: {
    height: 0,
    paddingTop: '56.25%', // 16:9
    cursor: 'pointer'
  }
})

const defaultFileUrl = 'https://miro.medium.com/max/250/1*DSNfSDcOe33E2Aup1Sww2w.jpeg'

export default function NFTCardCreation ({ collectionData, addNFTToList }) {
  const collectionId = collectionData.collectionId
  const { account, collectionContract, providerSigner } = useContext(Web3Context)
  const [file, setFile] = useState(null)
  const [fileUrl, setFileUrl] = useState(defaultFileUrl)
  const classes = useStyles()
  const { register, handleSubmit, reset } = useForm()
  const [isLoading, setIsLoading] = useState(false)

  async function createNft (metadataUrl, amountOfErc1155) {
    console.log('collectionId', collectionId, account, collectionContract)
    const transaction = await collectionContract.createNFT(collectionId, account, metadataUrl, amountOfErc1155)
    const tx = await transaction.wait()
    const event = tx.events.find(event => event.args)
    console.log('createNFT events', tx.events)
    const tokenId = event.args[0]
    return tokenId
  }

  function createNFTFormDataFile (name, description, file) {
    const formData = new FormData()
    formData.append('name', name)
    formData.append('description', description)
    formData.append('file', file)
    return formData
  }

  async function uploadFileToIPFS (formData) {
    const { data } = await axios.post('/api/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })

    return data.url
  }

  async function onFileChange (event) {
    if (!event.target.files[0]) return
    setFile(event.target.files[0])
    setFileUrl(URL.createObjectURL(event.target.files[0]))
  }

  async function onSubmit ({ name, description, amountOfErc1155 }) {
    try {
      if (!file || isLoading) return
      setIsLoading(true)
      console.log('NFT name', name, description)
      const formData = createNFTFormDataFile(name, description, file)
      const metadataUrl = await uploadFileToIPFS(formData)
      console.log('NFT metadataUrl', metadataUrl)
      const tokenId = await createNft(metadataUrl, amountOfErc1155)
      console.log('tokenId', tokenId)
      const nftContract = await getNftContract(collectionData.nftType, collectionData.nftAddress, providerSigner)
      addNFTToList(tokenId, nftContract)
      setFileUrl(defaultFileUrl)
      reset()
    } catch (error) {
      console.log(error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Card className={classes.root} component="form" sx={{ maxWidth: 345 }} onSubmit={handleSubmit(onSubmit)}>
      <label>
        NFT Create of Collection({collectionData.name})
      </label>
      <label htmlFor="file-input">
        <CardMedia
          className={classes.media}
          alt='Upload image'
          image={fileUrl}
        />
      </label>
      <input
        style={{ display: 'none' }}
        type="file"
        name="file"
        id="file-input"
        onChange={onFileChange}
      />
      <CardContent sx={{ paddingBottom: 0 }}>
        <TextField
          id="name-input"
          label="Name"
          name="name"
          size="small"
          fullWidth
          required
          margin="dense"
          disabled={isLoading}
          {...register('name')}
        />
        <TextField
          id="description-input"
          label="Description"
          name="description"
          size="small"
          multiline
          rows={2}
          fullWidth
          required
          margin="dense"
          disabled={isLoading}
          {...register('description')}
        />
        <TextField
          id="amountOfErc1155-input"
          label="amountOfErc1155"
          name="amountOfErc1155"
          defaultValue={0}
          size="small"
          multiline
          rows={2}
          fullWidth
          margin="dense"
          disabled={isLoading}
          {...register('amountOfErc1155')}
        />
      </CardContent>
      <CardActions className={classes.cardActions}>
        <Button size="small" type="submit">
          {isLoading
            ? <CircularProgress size="20px" />
            : 'Create'
          }
        </Button>
      </CardActions>
    </Card>
  )
}
