
# This file contains tools to iterate through the files that store the block
# chain on the hard drive.

# an iterator/stream chimera

# TODO: add fields for the current file and(? maybe not and) position in the
# file for faster comparison
mutable struct BCIterator
    io::IOStream
end

# This function does not make sense for i > 0, because we cannot be sure that in
# file i - 1 does not contain any blocks that come before the first block and
# that the first block of file i is actually the first block of the remaining
# chain.
function BCIterator(i::Integer)
    BCIterator(open(get_block_chain_file_path(i)))
end

BCIterator() = BCIterator(0)

# function Base.getindex(x::BCIterator, d::Symbol)
#     if     d == :file_name  x.io.name[end-12:end-1]
#     elseif d == :file_path  x.io.name[7:end-1]
#     elseif d == :file_index get_file_num(x)
#     else                    throw(KeyError(d))
#     end
# end

# # TODO: getproperty
# Base.getindex(x::BCIterator, ::Type{Val{:file_name}}) = x.io.name[end-12:end-1]
# Base.getindex(x::BCIterator, ::Type{Val{:file_path}}) = x.io.name[7:end-1]
# Base.getindex(x::BCIterator, ::Type{Val{:file_index}}) = x.io.name[7:end-1]

function is_last_file(x::BCIterator)
    get_num_block_chain_files() - 1 == get_file_num(x)
end

function open_next_file(x::BCIterator)
    if is_last_file(x)
        # TODO: don't use errors for programming logic
        throw(NoMoreFilesError())
    end
    new_file_idx = get_file_num(x) + 1
    # println(new_file_idx)
    close(x.io)
    x.io = open(get_block_chain_file_path(new_file_idx))
    return x
end

function get_file_num(x::BCIterator)
    parse(Int, x.io.name[end-9:end-5])
end

function get_file_pos(x::BCIterator)
    position(x.io)
end

function Base.:<(x::BCIterator, y::BCIterator)
    fn_x, fn_y = get_file_num(x), get_file_num(y)

    (fn_x < fn_y) ||
        ((fn_x == fn_y) &&
         get_file_pos(x) < get_file_pos(y))
end
Base.:>(x::BCIterator, y::BCIterator) = y < x
function Base.:<=(x::BCIterator, y::BCIterator)
    fn_x, fn_y = get_file_num(x), get_file_num(y)

    (fn_x < fn_y) ||
        ((fn_x == fn_y) &&
         get_file_pos(x) <= get_file_pos(y))
end
Base.:>=(x::BCIterator, y::BCIterator) = y <= x
function Base.:!=(x::BCIterator, y::BCIterator)
    (get_file_num(x) != get_file_num(y)) ||
        (get_file_pos(x) != get_file_pos(y))
end
function Base.:(==)(x::BCIterator, y::BCIterator)
    (get_file_num(x) == get_file_num(y)) &&
        (get_file_pos(x) == get_file_pos(y))
end


Base.close(x::BCIterator)      = close(x.io)
Base.read(x::BCIterator, T)    = read(x.io, T)
Base.read(x::BCIterator, T, n) = read(x.io, T, n)
Base.eof(x::BCIterator)        = eof(x.io)
Base.mark(x::BCIterator)       = mark(x.io)
Base.reset(x::BCIterator)      = reset(x.io)
Base.seekend(x::BCIterator)    = seekend(x.io)
Base.seekstart(x::BCIterator)  = seekstart(x.io)
Base.seek(x::BCIterator, pos)  = seek(x.io, pos)
Base.skip(x::BCIterator, off)  = skip(x.io, off)

# TODO: these functions do parsing and some of them are called all the time,
# the results should probably be cached
function get_block_chain_file_names()
    [x for x in readdir(DIR) if occursin(r"^blk", x)]
end
function get_block_chain_file_paths()
    [joinpath(DIR, x)
     for x in readdir(DIR) if occursin(r"^blk", x)]
end
function get_num_block_chain_files()
    length(get_block_chain_file_names())
end
function get_block_chain_file_name(i::Integer)
    "blk" * @sprintf("%05d", i) * ".dat"
end
function get_block_chain_file_path(i)
    joinpath(DIR, get_block_chain_file_name(i))
end

# TODO: should this function return something?
# function check_magic_bytes(io, the_magic::UInt32)
#     nextfourbytes = read(io, UInt32)
#     if nextfourbytes == zero(nextfourbytes)
#         nextfourbytes = read(io, UInt32)
#     end
#     if nextfourbytes != the_magic
#         throw(MagicBytesError(nextfourbytes))
#     end
#     nothing
# end
# check_magic_bytes(io) = check_magic_bytes(io, MAGIC)
function check_magic_bytes(io, the_magic::NTuple{4, UInt8})
    # at height 543617 there where some extra zero bytes after the block:
    while read(io, UInt8) == 0x00 end
    skip(io, -1)
    (read(io, UInt8) == the_magic[1] &&
     read(io, UInt8) == the_magic[2] &&
     read(io, UInt8) == the_magic[3] &&
     read(io, UInt8) == the_magic[4]) ||
     throw(MagicBytesError(0xffffffff))

    nothing
end
check_magic_bytes(io) = check_magic_bytes(io, to_byte_tuple(MAGIC))

"""
    seek_magic_bytes!(io, the_magic)

Advance `io` to next `the_magic`.
"""
function seek_magic_bytes!(io::IO, the_magic::NTuple{4, UInt8})
    @label a
    while read(io, UInt8) != the_magic[1] end
    if    read(io, UInt8) != the_magic[2] @goto a end
    if    read(io, UInt8) != the_magic[3] @goto a end
    if    read(io, UInt8) != the_magic[4] @goto a end
end

# I don't think this makes much sense here, they are about the same speed,
# @btime is not possible here, because it the function mutates io in place and we will reach EOF.
const CHAR_JUMP_TABLE = ntuple(i -> findfirst(isequal(UInt8(i - 1)), to_byte_tuple(MAGIC)) |>
                               x -> x == nothing ? UInt8(sizeof(MAGIC)) : UInt8(x - 1),
                               typemax(UInt8) + 1)

"""
    seek_magic_bytes_boyer_moore!(io, the_magic)

Advance `io` to next `the_magic`. Alternative implementation to `seek_magic_bytes!`
"""
function seek_magic_bytes_boyer_moore!(io::IO, the_magic::NTuple{4, UInt8})
    @label a
    # bad character rule
    current_byte = read(io, UInt8)
    if current_byte != the_magic[4]
        jump_length = CHAR_JUMP_TABLE[current_byte + 1]
        skip(io, jump_length)
        @goto a
    else
        skip(io, -2)
        current_byte = read(io, UInt8)
        if current_byte != the_magic[3]
            skip(io, 5)
            @goto a
        end

        skip(io, -2)
        current_byte = read(io, UInt8)
        if current_byte != the_magic[2]
            skip(io, 6)
            @goto a
        end

        skip(io, -2)
        current_byte = read(io, UInt8)
        if current_byte != the_magic[1]
            skip(io, 7)
            @goto a
        end

        skip(io, sizeof(the_magic) - 1)
    end
end
