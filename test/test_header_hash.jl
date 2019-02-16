
@testset "first header" begin

    bcio = BTCParser.BCIterator()

    block1 = Block(bcio)
    block2 = Block(bcio)

    hash1a = double_sha256(block1.header)
    hash1b = block2.header.previous_hash

    @test hash1a == hash1b

    close(bcio)

end
