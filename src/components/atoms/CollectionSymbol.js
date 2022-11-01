import { Typography } from '@mui/material'

export default function CollectionSymbol ({ symbol }) {
  return (
    <Typography
      variant="body2"
      color="text.secondary"
      gutterBottom
      >
        {symbol}
    </Typography>
  )
}
