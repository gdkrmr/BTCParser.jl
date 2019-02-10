# BTCParser.jl

[![Build Status](https://travis-ci.org/gdkrmr/BTCParser.jl.svg?branch=master)](https://travis-ci.org/gdkrmr/BTCParser.jl)
[![codecov.io](http://codecov.io/github/gdkrmr/BTCParser.jl/coverage.svg?branch=master)](http://codecov.io/github/gdkrmr/BTCParser.jl?branch=master)

## About

A pure Julia implementation of a [Bitcoin](https://bitcoincore.org/) blockchain
parser. Before using `BTCParser.jl` you must install a bitcoin client and
download the entire blockchain.

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
genesis_block = Block(chain[0])
```

Extract Block at height `h`
```julia
block = Block(chain[h])
```
chain indexing is 0-based to match the numbering used by the bitcoin core client,
if you require 1-based indexing, use `chain.data[h]`.

Get the hash of a block
```julia
double_sha256(genesis_block)
double_sha256(chain[0])
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

## Problems

- Currently only tested on `amd64` architectures under Linux
  - many of the internals are endian-dependent and may not work on other
    architectures.
  - Paths are different under Windows/MacOS.
- Testing requires a working copy of the Bitcoin blockchain (200GB) and therefore
  testing on travis is difficult.
- Grep the code for "TODO" for more stuff.
- Please report any issues or improvement proposals
  [here](https://github.com/gdkrmr/BTCParser.jl/issues).
