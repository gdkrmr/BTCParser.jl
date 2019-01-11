@testset "dump" begin

    n = 1000
    chain = make_chain(n)

    for i in eachindex(chain)
        b1 = chain[i] |> Block |> BTCParser.dump_block_data
        b2 = chain[i] |> BTCParser.dump_block_data
        @test b1 == b2
    end

end

@testset "dump segwit" begin

    # Points to the very first segwit transaction, probably only works on my
    # personal copy of the blockchain:
    #
    # The block is at height 481825 (one based, if you ask bitcoin-cli, height is
    # 481824)
    link = Link(
        BTCParser.to_unsigned((0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                               0x00, 0x1c, 0x80, 0x18, 0xd9, 0xcb, 0x3b, 0x74,
                               0x2e, 0xf2, 0x51, 0x14, 0xf2, 0x75, 0x63, 0xe3,
                               0xfc, 0x4a, 0x19, 0x02, 0x16, 0x7f, 0x98, 0x93)[end:-1:1]),
        UInt64(976),
        UInt64(0x577479)
    )

    b1 = Block(link) |> BTCParser.dump_block_data
    b2 = link |> BTCParser.dump_block_data

    @test b1 == b2
end
