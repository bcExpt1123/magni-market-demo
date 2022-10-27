import { Typography } from '@mui/material'

export default function CollectionDescription ({ description }) {
  return (
    <Typography
      variant="body2"
      color="text.secondary"
      gutterBottom
      >
        {description}
    </Typography>
  )
}
