@testset "make_chain" begin

    chain = make_chain(2)

    @test length(chain) == 2
    @test length(chain[1:1]) == 1
    @test typeof(chain[1]) == Link

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

    @test Header(chain[1])[:previous_hash] == double_sha256(chain[0])

end
