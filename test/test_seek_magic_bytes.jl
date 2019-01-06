
@testset "seek_magic_bytes" begin

    the_magic = BTCParser.to_byte_tuple(BTCParser.MAGIC)
    # const MAGIC = 0xf9be_b4d9
    bcio = BTCParser.BCIterator()
    BTCParser.seek_magic_bytes!(bcio.io, the_magic)
    @test position(bcio.io) == 0x4
    BTCParser.seek_magic_bytes!(bcio.io, the_magic)
    @test position(bcio.io) == 0x129
    BTCParser.seek_magic_bytes!(bcio.io, the_magic)
    @test position(bcio.io) == 0x208
    close(bcio)

end

@testset "seek_magic_bytes_boyer_moore" begin

    the_magic = BTCParser.to_byte_tuple(BTCParser.MAGIC)
    # const MAGIC = 0xf9be_b4d9
    bcio = BTCParser.BCIterator()
    BTCParser.seek_magic_bytes_boyer_moore!(bcio.io, the_magic)
    @test position(bcio.io) == 0x4
    BTCParser.seek_magic_bytes_boyer_moore!(bcio.io, the_magic)
    @test position(bcio.io) == 0x129
    BTCParser.seek_magic_bytes_boyer_moore!(bcio.io, the_magic)
    @test position(bcio.io) == 0x208
    close(bcio)

end

@testset "to_byte_tuple" begin

    bt = BTCParser.to_byte_tuple(0x1234_5678)
    @test length(bt) == 4
    @test bt[4] == 0x12
    @test bt[3] == 0x34
    @test bt[2] == 0x56
    @test bt[1] == 0x78

end
