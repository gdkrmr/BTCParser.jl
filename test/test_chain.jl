@testset "Chain" begin
    chain = make_chain(100)

    @test length(chain) == 100
    @test lastindex(chain) == 99

    @test collect(eachindex(chain)) == collect(0:99)

    @test checkbounds(Bool, chain, 0)
    @test checkbounds(Bool, chain, 99)
    @test checkbounds(Bool, chain, 0:99)

    @test !checkbounds(Bool, chain, -1)
    @test !checkbounds(Bool, chain, 100)
    @test !checkbounds(Bool, chain, 200)
    @test !checkbounds(Bool, chain, -1:99)
    @test !checkbounds(Bool, chain, 0:101)
    @test !checkbounds(Bool, chain, 1000:10001)

    @test nothing === checkbounds(chain, 0)
    @test nothing === checkbounds(chain, 99)
    @test nothing === checkbounds(chain, 0:99)

    @test_throws BoundsError checkbounds(chain, -1)
    @test_throws BoundsError checkbounds(chain, 100)
    @test_throws BoundsError checkbounds(chain, 200)
    @test_throws BoundsError checkbounds(chain, -1:99)
    @test_throws BoundsError checkbounds(chain, 0:101)
    @test_throws BoundsError checkbounds(chain, 1000:10001)

    @test first(chain) == first(chain.data)
    @test last(chain) == last(chain.data)

    @test chain[0] == chain.data[1]
    @test chain[end] == chain.data[end]
    @test chain[5] == chain.data[6]

    @test first(chain) == chain[0]
    @test last(chain) == chain[end]

    @test chain[0:4] isa BTCParser.Chain
    @test chain[0:4].data == chain.data[1:5]
    @test_throws BoundsError chain[1000:1001]
end
