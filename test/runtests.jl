
using BTCParser
using Test

using Ripemd
using SHA
using Base58

files = readdir(".")

# use only files that are named test_*.jl and start with the newest

filter!(x -> occursin(r"^test_.*\.jl$", x), files)
sort!(files, by = x -> stat(x).mtime, rev = true)

for f in files
    include(f)
end

