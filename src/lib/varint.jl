# These are the varints used in blocks! There are other varints used in the
# txindex data base!

# TODO: there should be a type VarInt and a read function

# TODO: little/big endian
"""
    read_varint(io::IO)::UInt64

Read a varint from `io`, find documentation
(here)[https://en.bitcoin.it/wiki/Protocol_documentation]
"""
function read_varint(io::IO)::UInt64
    i = read(io, UInt8)
    if     i <  0xFD UInt64(i)
    elseif i == 0xFD UInt64(read(io, UInt16))
    elseif i == 0xFE UInt64(read(io, UInt32))
    elseif i == 0xFF UInt64(read(io, UInt64))
    end
end

read_varint(x::BCIterator) = read_varint(x.io)

# We have to assume that the varint was always saved in the most space saving
# way for the following to work, no idea if this is guaranteed:
#
# TODO: this could return a tuple, this would avoid allocations but make this
# type unstable
"""
    to_varint(x::T)::Vector{UInt8}

Take an unsigned type and convert it into an varint
(here)[https://en.bitcoin.it/wiki/Protocol_documentation]

"""
function to_varint(x::T) where T
    if     x < T(0xFD)        UInt8[ UInt8(x) ]
    elseif x < T(0xFFFF)      UInt8[ 0xFD, to_byte_tuple(UInt16(x))... ]
    elseif x < T(0xFFFF_FFFF) UInt8[ 0xFE, to_byte_tuple(UInt32(x))... ]
    else                      UInt8[ 0xFF, to_byte_tuple(UInt64(x))... ]
    end
end
