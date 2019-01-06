
# struct Header
#     version           ::UInt32
#     previous_hash     ::UInt256 #Vector{UInt8} # length 32
#     merkle_root       ::UInt256 #Vector{UInt8} # length 32
#     timestamp         ::UInt32
#     difficulty_target ::UInt32
#     nounce            ::UInt32
# end
#
# The following implementation hopefully is
# more efficient, because no conversions at reading time have to be made:
"""
    Header

Data Structure representing the Header of a Block in the Bitcoin blockchain.

The elements of the `Header` can be accessed by `header[:element]`.

```julia
header[:version]
header[:previous_hash]
header[:merkle_root]
header[:timestamp]
header[:difficulty_target]
header[:nounce]
```

The hash of the `Header` can be retrieved with
```julia
double_sha256(header)
```
"""
struct Header
    data :: NTuple{80, UInt8}
end

Header(x::IO) = Header(ntuple((i) -> read(x, UInt8), 80))

function Header(bcio::BCIterator)

    check_magic_bytes(bcio)

    block_size = read(bcio, UInt32)

    block_header = Header(bcio.io)

    # @assert block_size - 80 > 0

    skip(bcio, block_size - 80)

    if eof(bcio)
        open_next_file(bcio)
    end

    block_header
end

# Header(x::BCIterator) = Header(x.io)
# Header(data::AbstractArray) = Header(reinterpret(UInt8, data))

# TODO: add getproperty methods for header

Base.getindex(x::Header, r) = x.data[r]

function Base.getindex(x::Header, d::Symbol)
    if     d == :version           to_unsigned(x[1:4])
    elseif d == :previous_hash     to_unsigned(x[5:36])
    elseif d == :merkle_root       to_unsigned(x[37:68])
    elseif d == :timestamp         to_unsigned(x[69:72])
    elseif d == :difficulty_target to_unsigned(x[73:76])
    elseif d == :nounce            to_unsigned(x[77:80])
    else throw(KeyError(d))
    end
end

Base.getindex(x::Header, ::Type{Val{:version}})           = to_unsigned(x[1:4])
Base.getindex(x::Header, ::Type{Val{:previous_hash}})     = to_unsigned(x[5:36])
Base.getindex(x::Header, ::Type{Val{:merkle_root}})       = to_unsigned(x[37:68])
Base.getindex(x::Header, ::Type{Val{:timestamp}})         = to_unsigned(x[69:72])
Base.getindex(x::Header, ::Type{Val{:difficulty_target}}) = to_unsigned(x[73:76])
Base.getindex(x::Header, ::Type{Val{:nounce}})            = to_unsigned(x[77:80])

function showcompact(io::IO, header::Header)
    println(io, "Header, " * string(header[:timestamp], base = 10) * ":")
end

function Base.show(io::IO, header::Header)
    showcompact(io, header)
    if !get(io, :compact, false)
        # TODO: add leading zeroes where necessary
        println(io, "  Version:    " * string(header[:version],           base = 16))
        println(io, "  Prev Hash:  " * string(header[:previous_hash],     base = 16))
        println(io, "  Root:       " * string(header[:merkle_root],       base = 16))
        println(io, "  Time:       " * string(header[:timestamp],         base = 10))
        println(io, "  Difficulty: " * string(header[:difficulty_target], base = 16))
        println(io, "  Nounce:     " * string(header[:nounce],            base = 10))
    end
end
# Base.showall(io::IO, header::Header) = show(io, header)

function double_sha256(x::Header)::UInt256
    x.data |> sha256 |> sha256 |>
        x -> reinterpret(UInt256, x)[1]
end
