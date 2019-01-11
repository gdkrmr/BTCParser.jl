@testset "TX hash" begin

    chain = make_chain(2)
    blk1 = Block(chain[0])
    tx1 = blk1.transactions[1]
    hash1 = double_sha256(tx1)
    @test string(hash1, base = 16) == "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"

end
