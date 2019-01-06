"""
    Block

Data Structure representing a Block in the Bitcoin blockchain.

Consists of a `block.header::Header` and
`block.transactions::Vector{Transaction}`.

To get the hash of a `Block`
```julia
double_sha256(block)
```
"""
struct Block
    size                :: UInt32
    header              :: Header
    transaction_counter :: UInt64
    transactions        :: Vector{Transaction}
end

function Block(io::IO)

    block_size = read(io, UInt32)

    block_header = Header(io)

    n_trans = read_varint(io)
    @assert n_trans > zero(n_trans)
    transactions = Transaction[
        Transaction(io)
        for i in 1:n_trans
    ]

    return Block(
        block_size,
        block_header,
        n_trans,
        transactions
    )
end

function Block(bcio::BCIterator)

    check_magic_bytes(bcio)
    block = Block(bcio.io)

    if eof(bcio)
        open_next_file(bcio)
    end

    return block
end

function Block(x::Array{UInt8})
    block_size = length(x)

    io = IOBuffer(x)

    block_header = Header(io)

    n_trans = read_varint(io)
    @assert n_trans > zero(n_trans)
    transactions = Transaction[
        Transaction(io)
        for i in 1:n_trans
    ]

    return Block(
        block_size,
        block_header,
        n_trans,
        transactions
    )
end

function showcompact(io::IO, block::Block)
    @printf(io, "Block, %d bytes, %d transactions:\n",
            block.size, block.transaction_counter)
end

function Base.show(io::IO, block::Block)
    showcompact(io, block)
    if !get(io, :compact, false)
        show(io, block.header)
    end
end

# function Base.showall(io::IO, block::Block)
#     show(io, block)
#     println("Transactions:")
#     show(io, block.transactions)
# end

"""
    double_sha256(x::Block)::UInt256
    double_sha256(x::Header)::UInt256
    double_sha256(x::Transaction)::UInt256

Hash a `Block`, `Header`, or `Transaction`

```julia
double_sha256(block)
double_sha256(header)
double_sha256(transaction)
```
"""
double_sha256(x::Block) = double_sha256(x.header)


function dump_block_data(io::IO)
    block_size = read(io, UInt32)
    read!(io, Array{UInt8}(undef, block_size))
end

function dump_block_data(bcio::BCIterator)
    check_magic_bytes(bcio)
    dump_block_data(bcio.io)
end

function dump_block_data(block::Block)

    data = Array{UInt8}(undef, block.size)

    copyto!(data, 1, block.header.data)

    transaction_counter = to_varint(block.transaction_counter)
    copyto!(data, 81, transaction_counter)
    idx = 81 + length(transaction_counter)

    for i in 1:block.transaction_counter
        idx = dump_tx_data!(data, idx, block.transactions[i])
    end

    @assert idx == length(data) + 1

    return data
end

function Block(fp::FilePointer)
    fp.file_number |>
        get_block_chain_file_path |>
        x -> open(x) do fh
            seek(fh, fp.file_position)
            Block(fh)
        end
end
