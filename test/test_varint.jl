
@testset "VarInt" begin

    io = IOBuffer()
    write(io, UInt8[0x05])
    seekstart(io)
    @test BTCParser.read_varint(io) == 0x0000_0000_0000_0005

    io = IOBuffer()
    write(io, UInt8[0xfd, 0x00, 0x05])
    seekstart(io)
    @test BTCParser.read_varint(io) == 0x0000_0000_0000_0500

    io = IOBuffer()
    write(io, UInt8[0xfe, 0x00, 0x00, 0x00, 0x05])
    seekstart(io)
    @test BTCParser.read_varint(io) == 0x0000_0000_0500_0000

    io = IOBuffer()
    write(io, UInt8[0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05])
    seekstart(io)
    @test BTCParser.read_varint(io) == 0x0500_0000_0000_0000

end
