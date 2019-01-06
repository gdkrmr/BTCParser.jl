# BTCParser.jl

[![Build Status](https://travis-ci.org/gdkrmr/BTCParser.jl.svg?branch=master)](https://travis-ci.org/gdkrmr/BTCParser.jl)
[![codecov.io](http://codecov.io/github/gdkrmr/BTCParser.jl/coverage.svg?branch=master)](http://codecov.io/github/gdkrmr/BTCParser.jl?branch=master)

## About

A pure Julia implementation of a [Bitcoin](https://bitcoincore.org/) Blockchain
parser. Before using it you must install a bitcoin client and download the
Blockchain.

Bitcoin core should save the blockchain data into `$HOME/.bitcoin/blocks`,
`BTCParser.jl` will look there by default. You can change this directory by
setting the environmental variable `BTCPARSER_BLOCK_DIR`.

## Usage

Read the chain:

```julia
using BTCParser

# this takes ~2-3 minues on a SATA SSD
chain = make_chain()
```

Extract the Genesis Block
```julia
genesis_block = Block(chain[1])
```

Extract Block at height `h`
```julia
block = Block(chain[h])
```
Mind that Julia arrays are 1-based, while the bitcoin blockchain is 0-based.

Get the hash of a block
```julia
double_sha256(genesis_block)
double_sha256(chain[1])
```

Get the header of a block
```julia
Header(chain[1])
Header(genesis_block)
```

Access transactions
```julia
genesis_tx = genesis_block.transactions[1]
```

Hashing transactions
```julia
double_sha256(genesis_tx)
```

Update an existing chain (in case the bitcoin client is running in the background)
```julia
chain = make_chain(chain)
```
