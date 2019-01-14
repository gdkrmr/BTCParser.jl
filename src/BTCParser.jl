module BTCParser

import SHA
import SHA: sha256
import Ripemd: ripemd160
using Printf

export
    UInt256, Link,
    Block, Header,
    Transaction, TransactionInput, TransactionOutput,
    Witness,
    make_chain, double_sha256


"""
The path where the bitcoin client saves the blockchain files.
"""
const DIR = if haskey(ENV, "BTCPARSER_BLOCK_DIR")
    ENV["BTCPARSER_BLOCK_DIR"]
else
    joinpath(ENV["HOME"], ".bitcoin", "blocks")
end

const HEADER_SIZE = 80

# This reads reversed compared to the byte order
# TODO: big endian little endian
const MAGIC = 0xd9b4_bef9
const MAGIC_SIZE = sizeof(eltype(MAGIC))

include("lib/errors.jl")
include("lib/uint256.jl")
include("lib/conversions.jl")
include("lib/file_ops.jl")
include("lib/varint.jl")
include("lib/transaction.jl")
include("lib/header.jl")
include("lib/block.jl")
include("lib/chain.jl")

end # module
