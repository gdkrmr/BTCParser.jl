function nbytes_to_unsigned_type(n)
    if     n == 1  UInt8
    elseif n == 2  UInt16
    elseif n == 4  UInt32
    elseif n == 8  UInt64
    elseif n == 16 UInt128
    else "Length of n must be a power of two and maximum 16." |>
        ArgumentError |> throw
    end
end

# TODO: little endian only
# This one gets optimized out completely in 0.7+ :-)
"""
    BTCParser.to_unsigned(x::NTuple{N, UInt8})::Unsigned

Convert a tuple to an unsigned (`UInt8`, `UInt16`, `UInt32`, `UInt64`,
`UInt128`, `UInt256`) with the identical order of bits.

Results depend on the endianness of your CPU architecture.
"""
@generated function to_unsigned(x::NTuple{N, UInt8}) where N

    T = nbytes_to_unsigned_type(N)

    sb = ntuple(i -> T(1) << (8 * (i - 1)), N)

    ex = :($T(0))
    for i in 1:N
        ex = :($ex + $sb[$i] * x[$i])
    end

    return ex
end

# TODO: figure out a no-op way to do this
function to_unsigned(x::NTuple{32, UInt8})
    x |> Ref |>
        x -> Base.unsafe_convert(Ptr{NTuple{32, UInt8}}, x) |>
        x -> convert(Ptr{UInt256}, x) |>
        x -> unsafe_load(x)
end

# TODO: figure out a no-op way to do this
function to_byte_tuple(x::T) where T <: Union{UInt256, UInt128}
    x |>
        Ref |>
        x -> Base.unsafe_convert(Ptr{T}, x) |>
        x -> convert(Ptr{NTuple{sizeof(T), UInt8}}, x) |>
        x -> unsafe_load(x)
end

# TODO: Little endian only
# TODO: figure out a no-op way to do this
# NOTE: This is really slow for UInt128
"""
    BTCParser.to_byte_tuple(x::Unsigned)::NTuple{N, UInt8}

Convert an `Unsigned` (`UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt128`,
`UInt256`) into an `NTuple{N, UInt8}` with the identical order of bits.

Results depend on the endianness of your CPU architecture.
"""
function to_byte_tuple(x::T) where T <: Unsigned
    ntuple(i -> (x >> (8 * (i - 1))) % UInt8, sizeof(T))
end
