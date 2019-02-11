# using Pkg
# Pkg.activate("/home/gkraemer/progs/julia/BTCParser")
# using Revise
# using BTCParser

@testset "BCIterator" begin
    for i in 0:100
        b = BTCParser.BCIterator(i)
        @test BTCParser.get_file_num(b) == i
        close(b)
    end

    n_files = BTCParser.get_num_block_chain_files()
    b = BTCParser.BCIterator(n_files - 1)
    @test BTCParser.is_last_file(b)
    close(b)

    b = BTCParser.BCIterator()
    i = 0
    @test BTCParser.get_file_num(b) == i
    while !BTCParser.is_last_file(b)
        i += 1
        BTCParser.open_next_file(b)
        @test i == BTCParser.get_file_num(b)
    end
    close(b)

    b = BTCParser.BCIterator()
    BTCParser.check_magic_bytes(b)
    @test BTCParser.get_file_pos(b) == 4

    b2 = BTCParser.BCIterator()

    @test b  >  b2
    @test b  >= b2
    @test b2 <= b
    @test b2 <  b

    BTCParser.check_magic_bytes(b2)
    @test b == b2

    close(b)
    close(b2)

end
