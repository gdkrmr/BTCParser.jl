struct NoMoreFilesError <: Exception end
Base.showerror(io::IO, e::NoMoreFilesError) = print(io, "No more block files")

struct MagicBytesError <: Exception
    bytes :: UInt32
end
Base.showerror(io::IO, e::MagicBytesError) =
    print(io, "Wrong Magic Bytes: ", string(e.bytes, base = 16))
