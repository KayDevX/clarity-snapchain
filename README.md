# SnapChain

A decentralized photography NFT platform built on Stacks blockchain. SnapChain allows photographers to mint their photos as unique NFTs with metadata including camera settings, location, and timestamp.

## Features
- Mint photo NFTs with detailed metadata
- Batch mint multiple photos in one transaction
- Transfer NFTs between users
- View photo metadata and ownership history
- Automatic 5% royalty payments to original photographers on secondary sales
- Photographer statistics tracking including total sales and royalties earned

## Contract Functions
- `mint-photo`: Create a new photo NFT with metadata
- `batch-mint-photos`: Mint multiple photos in a single transaction
- `transfer`: Transfer NFT ownership
- `get-photo-data`: Retrieve photo metadata
- `list-for-sale`: List NFT on marketplace
- `buy-photo`: Purchase listed NFT with automatic royalty payment
- `get-photographer-stats`: View photographer's platform statistics

## Royalty System
The platform automatically handles royalty payments to original photographers:
- 5% royalty on all secondary sales
- Royalties are paid directly to the photographer's wallet
- Photographer statistics track total sales and earned royalties

## Batch Minting
Photographers can now mint up to 10 photos in a single transaction:
- Reduces transaction fees
- More efficient for uploading photo collections
- Maintains all metadata and royalty functionality
