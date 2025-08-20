# 🎵 Randomized Music NFT Generator

A Stacks smart contract that generates unique music track NFTs with randomized properties based on on-chain seeds.

## 🎨 Features

- 🎲 **Randomized Generation**: Each track has unique properties generated from blockchain data
- 🎼 **Rich Metadata**: Tracks include title, genre, tempo, key, instruments, and duration
- 🎪 **Multiple Genres**: Electronic, Rock, Jazz, Classical, Ambient, Hip-Hop, Techno, House
- 🎹 **Instrument Combinations**: Piano, Guitar, Bass, Drums, Synth, Violin, Trumpet, Flute, Saxophone, Cello
- 🔥 **Standard NFT Functions**: Mint, transfer, burn with full ownership tracking

## 🚀 Quick Start

### Deploy Contract

```bash
clarinet console
```

### Mint Your First Track

```clarity
(contract-call? .Randomized-Music-NFT-Generator mint-track tx-sender)
```

### View Track Metadata

```clarity
(contract-call? .Randomized-Music-NFT-Generator get-track-metadata u1)
```

## 📋 Contract Functions

### 🎯 Core Functions

| Function | Description |
|----------|-------------|
| `mint-track` | 🎨 Mint a new randomized music track NFT |
| `transfer` | 📤 Transfer track ownership |
| `burn` | 🔥 Permanently destroy a track |
| `batch-mint` | 🎭 Mint multiple tracks (owner only) |

### 📊 Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-track-metadata` | 🎵 Get track details (title, genre, tempo, etc.) |
| `get-owner` | 👤 Get track owner |
| `get-track-count` | 🔢 Get number of tracks owned by address |
| `get-next-token-id` | 🆔 Get next available token ID |
| `get-track-uri` | 🔗 Get track metadata URI |

## 🎲 Randomization System

The contract generates unique tracks using:
- **Block Height**: Current Stacks block height
- **Block Hash**: Current block hash for entropy  
- **Token ID**: Sequential ID for uniqueness

### 🎼 Generated Properties

- **Title**: "Midnight Beats", "Digital Dreams", "Cosmic Waves", "Electric Soul"
- **Genre**: 8 different musical genres
- **Tempo**: 60-200 BPM
- **Key**: All 12 musical keys (C, C#, D, etc.)
- **Instruments**: Up to 3 random instruments per track
- **Duration**: 2-7 minutes (120-420 seconds)

## 💻 Usage Examples

### Mint a Track
```clarity
(contract-call? .Randomized-Music-NFT-Generator mint-track 'SP1EXAMPLE...)
```

### Transfer a Track
```clarity
(contract-call? .Randomized-Music-NFT-Generator transfer u1 tx-sender 'SP2RECIPIENT...)
```

### Check Track Details
```clarity
(contract-call? .Randomized-Music-NFT-Generator get-track-metadata u1)
;; Returns: {title: "Digital Dreams", genre: "Electronic", tempo: u128, ...}
```

## 🏗️ Technical Details

- **Standard**: SIP-009 NFT Standard
- **Language**: Clarity
- **Platform**: Stacks Blockchain
- **Max Supply**: Unlimited
- **Metadata**: Stored on-chain

## 🧪 Testing

Run tests with Clarinet:

```bash
clarinet test
```

## 📝 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes  
4. Push to the branch
5. Create a Pull Request

---

🎵 **Generate your unique music NFT collection today!** 🎵
