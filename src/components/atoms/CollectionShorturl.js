import { Typography } from '@mui/material'

export default function CollectionShorturl ({ shorturl }) {
  return (
    <Typography
      variant="body2"
      color="text.secondary"
      gutterBottom
      >
        {shorturl}
    </Typography>
  )
}
