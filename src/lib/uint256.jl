
"""
    UInt256

256 bit unsigned integer, only a few operations are implemented. Holds the hash
value of `Block` and `Transaction`.

# Example

```julia
double_sha256(block)
double_sha256(tx)

zero(UInt256)
UInt256("234")
BTCParser.to_unsigned((0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03,
                       0x00, 0x01, 0x02, 0x03))
```
"""
primitive type UInt256 <: Unsigned 256 end

# promotion_rule(::Type{UInt256}, ::Type{UInt}) = UInt256

# print does not work, have to implement
# ndigits0z(x::UInt256)

Base.show(io::IOStream, x::UInt256) = show(io, "0x" * string(x, base = 16))

# Base.show(io::IOStream, x::Array{UInt256}) = show(io, reinterpret(UInt8, x))

# Base.print(io::IOStream, x::UInt256)        = print(io, string(x, base = 16))
# Base.print(io::IOStream, x::Array{UInt256}) = show(io, x)

# Base.display(io::IOStream, x::UInt256)        = show(x)
# Base.display(io::IOStream, x::Array{UInt256}) = print(x)

# TODO: pad is currently being ignored
function Base.string(x::UInt256; base = 10, pad::Int = 0, neg::Bool = false)

    # The below only works if base is a power of 2, for now restrict it to 16
    # only...
    @assert base == 16

    x |> to_byte_tuple |>
        y -> map(i -> string(y[i], base = base, pad = 2), 32:-1:1) |>
        z -> string(z...)
    # tmp1 = convert(Ptr{UInt8}, pointer_from_objref(x))
    # tmp3 = map(i -> string(unsafe_load(tmp1, i), base = base, pad = pad), 32:-1:1)
    # string(tmp3...)
end

# TODO: I don't think there is a way to do this with bitwise operators in julia
function Base.bswap(x::UInt256)
    reinterpret(UInt256, reinterpret(UInt8, UInt256[x])[end:-1:1])[1]
end

function Base.zero(x::UInt256)
    reinterpret(UInt256, zeros(UInt8, 32))[1]
end

function Base.zero(::Type{UInt256})
    reinterpret(UInt256, zeros(UInt8, 32))[1]
end


# this one takes ~ 2x as long
# function Base.bswap(x::UInt256)
#     convert(UInt256, convert(NTuple{32, UInt8}, x)[end:-1:1])
# end

# Required to use this as keys in Dict
# TODO: this is probably not good:
Base.hash(x::UInt256, h::UInt) = Base.hash(x % UInt64, h)
Base.hash(x::UInt256) = Base.hash(x, zero(UInt))

# Base.rem(x::UInt256, ::Type{T}) where T = reinterpret(T,  Int256[x])[1]
# TODO: big/little endian
function Base.rem(x::UInt256, ::Type{T}) where {T <: Integer}
    Ref(x) |>
        pointer_from_objref |>
        x -> convert(Ptr{T}, x) |>
        unsafe_load
end

# Should probably be `parse`
# TODO: untested!!!
# TODO: optimize!!!
function UInt256(x::AbstractString)
    n = length(x)
    @assert n <= 64
    if n <= 32
        to_unsigned((to_byte_typle(Base.parse(UInt128, x, base = 16))...,
                     to_byte_tuple(zero(UInt128))...))
    else
        to_unsigned(
                    (to_byte_tuple(Base.parse(UInt128, String(x[end - 31:end]),      base = 16))...,
                     to_byte_tuple(Base.parse(UInt128, String(x[       1:end - 32]), base = 16))...) )
    end
end
