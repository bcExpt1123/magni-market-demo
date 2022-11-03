
import { useContext, useState } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { makeStyles } from '@mui/styles'
import { TextField, Card, CardActions, CardContent, CardMedia, Button, CircularProgress, RadioGroup, FormControlLabel, Radio } from '@mui/material'
import axios from 'axios'
import { Web3Context } from '../providers/Web3Provider'

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

export default function CollectionCardCreation ({ addCollectionToList }) {
  const [file, setFile] = useState(null)
  const [fileUrl, setFileUrl] = useState(defaultFileUrl)
  const classes = useStyles()
  const { register, handleSubmit, reset, control } = useForm({
    defaultValues: {
      nfttype: 0
    }
  })
  const { collectionContract } = useContext(Web3Context)
  const [isLoading, setIsLoading] = useState(false)

  async function createCollection (nfttype, name, symbol, shorturl, metadataUrl) {
    const transaction = await collectionContract.createCollection(nfttype, name, symbol, shorturl, metadataUrl)
    const tx = await transaction.wait()
    console.log('createCollection events', tx.events)
    const event = tx.events[0]
    const collectionId = event.args[0]
    return collectionId
  }

  function createCollectionFormDataFile (name, symbol, shorturl, description, file) {
    const formData = new FormData()
    formData.append('name', name)
    formData.append('symbol', symbol)
    formData.append('shorturl', shorturl)
    formData.append('description', description)
    formData.append('file', file)
    return formData
  }

  async function uploadFileToIPFS (formData) {
    const { data } = await axios.post('/api/upload-collection', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })

    return data.url
  }

  async function onFileChange (event) {
    if (!event.target.files[0]) return
    setFile(event.target.files[0])
    setFileUrl(URL.createObjectURL(event.target.files[0]))
  }

  async function onSubmit ({ nfttype, name, symbol, shorturl, description }) {
    console.log('nfttype', nfttype, name)
    try {
      if (!file || isLoading) return
      setIsLoading(true)
      const formData = createCollectionFormDataFile(name, symbol, shorturl, description, file)
      const metadataUrl = await uploadFileToIPFS(formData)
      const collectionId = await createCollection(nfttype, name, symbol, shorturl, metadataUrl)
      addCollectionToList(collectionId)
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
        <Controller
          rules={{ required: true }}
          control={control}
          name="nfttype"
          render={({ field }) => (
            <RadioGroup {...field}
              aria-labelledby="demo-radio-buttons-group-label"
              defaultValue="0"
            >
              <FormControlLabel value="0" control={<Radio />} label="ERC721" />
              <FormControlLabel value="1" control={<Radio />} label="ERC1155" />
            </RadioGroup>
          )}
        />
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
          id="name-input"
          label="Symbol"
          name="symbol"
          size="small"
          fullWidth
          required
          margin="dense"
          disabled={isLoading}
          {...register('symbol')}
        />
        <TextField
          id="name-input"
          label="Short URL"
          name="shorturl"
          size="small"
          fullWidth
          required
          margin="dense"
          disabled={isLoading}
          {...register('shorturl')}
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
