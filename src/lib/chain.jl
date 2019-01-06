# Make Chain without transaction pool


# TODO: check if it is better to use something like
# struct Link
#     hash :: Array{UInt256, 1}
#     ...
# end
# instead

"""
    Link

The elements of the chain, only for internal representation.

```
link = chain[1]
Block(link)
Header(link)
double_sha256(link)
```
"""
struct Link
    hash          :: UInt256
    file_number   :: UInt64
    file_position :: UInt64
end

Link() = Link(zero(UInt256), typemax(UInt64), typemax(UInt64))

double_sha256(link::Link)     = link.hash
get_file_pos(link::Link) = link.file_position
get_file_num(link::Link) = link.file_number

# function Base.show(io::IO, link::Link)
#     println(io, "Link:")
#     println(io, "  File number: " * string(get_file_num(link), base = 10))
#     println(io, "  Position:    " * string(get_file_pos(link), base = 16))
# end
function Base.show(io::IO, link::Link)
    println(io, "Link:")
    if !get(io, :limit, false)
        println(io, "  Hash:        " * string(double_sha256(link), base = 16))
    end
    println(io, "  File number: " * string(get_file_num(link), base = 10))
    println(io, "  Position:    " * string(get_file_pos(link), base = 16))
end

# TODO: make this zero based!
"""
    Chain

`Vector{Link}`, data type to represent blockchain.

```julia
chain = make_chain()
```
"""
const Chain = Array{Link, 1}

function Base.show(io::IO, chain::Chain)
    println(io, "Chain length " * string(length(chain), base = 10))
end

# function Base.showall(io::IO, chain::Chain)
#     show(io, chain)
#     for i in 1:length(chain)
#         show(io, chain[i])
#     end
# end

# struct Chain
#     data :: Array{Link, 1}
# end
#
# Chain() = Chain(Array(0, 1))
# push!(chain::Chain, link::Link) = push!(chain.data, link)
# length(chain::Chain) = length(chain.data)
# getindex(chain::Chain, key...) = getindex(chain, key...)

function Header(link::Link)

    # fn = get_block_chain_file_path(get_file_num(link))
    # open(fn) do fh

    link |>
        get_file_num |>
        get_block_chain_file_path |>
        x -> open(x) do fh

            seek(fh, get_file_pos(link))
            check_magic_bytes(fh)

            # Skip the Blocksize UInt32:
            skip(fh, sizeof(UInt32))

            Header(fh)
        end
end

function Block(link::Link)

    # fn = get_block_chain_file_path(get_file_num(link))
    # open(fn) do fh

    link |>
        get_file_num |>
        get_block_chain_file_path |>
        x -> open(x) do fh

            seek(fh, get_file_pos(link))
            check_magic_bytes(fh)

            Block(fh)
        end
end

function dump_block_data(link::Link)
    link |>
        get_file_num |>
        get_block_chain_file_path |>
        x -> open(x) do fh
            seek(fh, get_file_pos(link))
            check_magic_bytes(fh)
            dump_block_data(fh)
        end
end


function link_and_prev_hash(bcio::BCIterator)

    file_pos = get_file_pos(bcio)
    file_num = get_file_num(bcio)

    header = Header(bcio)
    block_hash = double_sha256(header)

    prev_block_hash = header[Val{:previous_hash}]

    Link(block_hash, file_num, file_pos), prev_block_hash
end

function check_out_of_order_blocks!(
    chain,
    out_of_order_blocks,
    out_of_order_prev_hashes
)
    # TODO: optimize this using a linked list? or a Dict or other kind of hash
    # table

    @assert length(out_of_order_blocks) == length(out_of_order_prev_hashes)

    @label start
    for l in eachindex(out_of_order_blocks)

        if out_of_order_prev_hashes[l] == chain[end].hash

            push!(chain, out_of_order_blocks[l])

            deleteat!(out_of_order_blocks, l)
            deleteat!(out_of_order_prev_hashes, l)

            @goto start
        end
    end

    return nothing
end

function BCIterator(x::Link)
    bcio = BCIterator(get_file_num(x))
    BCIterator(seek(bcio, get_file_pos(x)))
end

"""
    make_chain(chain::Chain, height::Integer)::Chain
    make_chain(chain::Chain)::Chain
    make_chain(height::Integer)::Chain
    make_chain()::Chain

Read a chain of `height` or the entire bockchain, if `height` is not specified.
If `chain` is supplied, update the given chain.
"""
function make_chain(
    chain                   :: Chain,
    height                  :: Integer,
    # This is hardcoded in the bitcoin reference client:
    max_out_of_order_blocks :: Integer = 1024
)

    if length(chain) <= max_out_of_order_blocks
        bcio = BCIterator()::BCIterator
        chain = Chain()
    else
        bcio = BCIterator(chain[end - max_out_of_order_blocks + 1])::BCIterator
        chain = chain[1:(end - max_out_of_order_blocks)]
    end

    out_of_order_blocks = Chain()
    out_of_order_prev_hashes = UInt256[]

    link, prev_block_hash = link_and_prev_hash(bcio)

    push!(chain, link)

    # TODO: if height is larger the actual chain length, this will run forever
    while length(chain) < height

        # TODO: don't use errors for programming logic
        try
            link, prev_block_hash = link_and_prev_hash(bcio)
        catch e
            if typeof(e) == NoMoreFilesError
                return chain
            elseif typeof(e) == EOFError
                return chain
            elseif typeof(e) == MagicBytesError
                # block file are padded with zeros
                if e.bytes == zero(UInt32)
                    # return chain
                    @show chain[end]
                    # rethrow(e)
                    return chain
                else
                    @show chain[end]
                    rethrow(e)
                end
            else
                @show chain[end]
                rethrow(e)
            end
        end

        if chain[end].hash == prev_block_hash
            push!(chain, link)
        else
            push!(out_of_order_blocks, link)
            push!(out_of_order_prev_hashes, prev_block_hash)
            check_out_of_order_blocks!(
                chain,
                out_of_order_blocks,
                out_of_order_prev_hashes
            )
        end

    end

    return chain
end

make_chain()             = make_chain(Chain(), typemax(Int))
make_chain(n::Int)       = make_chain(Chain(), n)
make_chain(chain::Chain) = make_chain(chain, typemax(Int))

# TODO: figure out when the chain is complete
# function make_chain()

#     chain = Chain()
#     bcio = BCIterator()

#     while (true)

#         file_pos = get_file_pos(bcio)
#         file_num = get_file_num(bcio)
#         block = bnet.Block(bcio)
#         block_hash = hash(block)

#         link = Link(block_hash, file_num, file_pos)
#         push!(chain, link)

#         # TODO: define break condition when the chain is complete
#         if()
#             break
#         end


#     end

#     return chain
# end

"""
    make_chain_dict

Alternative implementation of `make_chain`.
"""
function make_chain_dict(
    chain                   :: Chain,
    height                  :: Integer,
    # This is hardcoded in the bitcoin reference client:
    max_out_of_order_blocks :: Integer = 1024
)

    if length(chain) <= max_out_of_order_blocks
        bcio = BCIterator()::BCIterator
        chain = Chain()
    else
        bcio = BCIterator(chain[end - max_out_of_order_blocks + 1])::BCIterator
        chain = chain[1:(end - max_out_of_order_blocks)]
    end


    out_of_order_blocks = Dict{UInt256, Link}()
    # out_of_order_blocks = ObjectIdDict()

    link, prev_block_hash = link_and_prev_hash(bcio)

    push!(chain, link)

    while length(chain) < height

        # TODO: don't use errors for programming logic!!!
        try
            link, prev_block_hash = link_and_prev_hash(bcio)
        catch e
            if typeof(e) == NoMoreFilesError
                return chain
            elseif typeof(e) == MagicBytesError
                # block file are padded with zeros
                if e.bytes == zero(UInt32)
                    return chain
                else
                    @show chain[end]
                    rethrow(e)
                end
            else
                @show chain[end]
                rethrow(e)
            end
        end

        if chain[end].hash == prev_block_hash
            push!(chain, link)
        else
            out_of_order_blocks[prev_block_hash] = link

            while true
                try
                    # ObjectIdDict is {Any, Any}
                    push!(chain, pop!(out_of_order_blocks, chain[end].hash)::Link)
                catch
                    break
                end
            end

            # while haskey(out_of_order_blocks, chain[end].hash)
            #     # ObjectIdDict is {Any, Any}
            #     push!(chain, pop!(out_of_order_blocks, chain[end].hash)::Link)
            # end
        end

    end

    return chain
end
