@testset "make_chain" begin

    @inferred make_chain(2)

    chain = make_chain(2)

    genesis_block = chain[0]
    @test double_sha256(genesis_block) ==
        UInt256("000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")

    @test length(chain) == 2
    @test length(chain[1:1]) == 1
    @test chain[1] isa Link

    @test chain[0].hash == double_sha256(chain[0])
    @test chain[1].hash == double_sha256(chain[1])

    @test BTCParser.get_file_pos(chain[0]) == 0x0
    @test BTCParser.get_file_num(chain[0]) == 0
    @test BTCParser.get_file_pos(chain[1]) == 0x125
    @test BTCParser.get_file_num(chain[1]) == 0

    @test double_sha256(Header(chain[0])) == double_sha256(chain[0])
    @test double_sha256(Header(chain[1])) == double_sha256(chain[1])
    @test double_sha256(Block(chain[0]))  == double_sha256(chain[0])
    @test double_sha256(Block(chain[1]))  == double_sha256(chain[1])

    @test Header(chain[1]).previous_hash == double_sha256(chain[0])

    # TODO: should these be == ? I think the reason that these are longer is
    # that make chain finishes the out of order blocks.
    chain100 = make_chain(chain, 100)
    @test length(chain100) >= 100
    @test chain100[0] == genesis_block

    chain4000 = make_chain(deepcopy(chain100), 4000)
    @test length(chain4000) >= 4000
    @test chain4000[0] == genesis_block
    @test chain100[end] == chain4000[99]

    chain8000 = make_chain(chain4000, 8000)
    @test length(chain8000) >= 8000
    @test chain8000[0] == genesis_block
    @test chain100[end] == chain8000[99]
    @test chain4000[end] == chain8000[3999]
end
