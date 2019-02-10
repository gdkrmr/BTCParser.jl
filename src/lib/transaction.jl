raw"""
All the inputs are consumed and the difference of the output sums goes to the
miner

Input hashes and output index point to the original transaction
The unlocking script must match the locking script

Transaction:
  - Version
  - Input Counter
  - Inputs
    - hash
        The transaction origin id
    - output index
        The transacion output idx
    - unlocking script size
    - unlocking script
    - sequence number
  - Outputs
    - amount
    - locking script size
    - locking script

Hexdump of the genesis block area blk00000.dat:


f9be b4d9 1d01 0000 0100 0000 0000 0000  ................
^^^^^^^^^ magic bytes
          ^^^^^^^^^ block size
                    ^^^^^^^^^ version
                              ^^^^^^^^^
0000 0000 0000 0000 0000 0000 0000 0000  ................
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
0000 0000 0000 0000 0000 0000 3ba3 edfd  ............;...
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ previous hash
                              ^^^^^^^^^
7a7b 12b2 7ac7 2c3e 6776 8f61 7fc8 1bc3  z{..z.,>gv.a....
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
888a 5132 3a9f b8aa 4b1e 5e4a 29ab 5f49  ..Q2:...K.^J)._I
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ merkle root
                              ^^^^^^^^^ time stamp
ffff 001d 1dac 2b7c 0101 0000 0001 0000  ......+|........
^^^^^^^^^ difficulty
          ^^^^^^^^^ nonce
                    ^^ number of transactions (varint)
                      ^^^^^^^^^^ version
                                ^^ number of inputs
                                   ^^^^
0000 0000 0000 0000 0000 0000 0000 0000  ................
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
0000 0000 0000 0000 0000 0000 0000 ffff  ................
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ originating transaction hash
                                   ^^^^
ffff 4d04 ffff 001d 0104 4554 6865 2054  ..M.......EThe T
^^^^ output index of the originating transaction
     ^^ script length (varint)
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
696d 6573 2030 332f 4a61 6e2f 3230 3039  imes 03/Jan/2009
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
2043 6861 6e63 656c 6c6f 7220 6f6e 2062   Chancellor on b
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
7269 6e6b 206f 6620 7365 636f 6e64 2062  rink of second b
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
6169 6c6f 7574 2066 6f72 2062 616e 6b73  ailout for banks
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ unlocking script
ffff ffff 0100 f205 2a01 0000 0043 4104  ........*....CA.
^^^^^^^^^ sequence number
          ^^ number of outputs
            ^^^^^^^^^^^^^^^^^^^^ amount (Big endian Float64)
                                ^^ script length
                                   ^^^^
678a fdb0 fe55 4827 1967 f1a6 7130 b710  g....UH'.g..q0..
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
5cd6 a828 e039 09a6 7962 e0ea 1f61 deb6  \..(.9..yb...a..
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
49f6 bc3f 4cef 38c4 f355 04e5 1ec1 12de  I..?L.8..U......
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
5c38 4df7 ba0b 8d57 8a4c 702b 6bf1 1d5f  \8M....W.Lp+k.._
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ac00 0000 00f9 beb4 d9d7 0000 0001 0000  ................
^^ locking script
  ^^^^^^^^^^ lock time
            ^^^^^^^^^^ magic bytes
006f e28c 0ab6 f1b3 72c1 a6a2 46ae 63f7  .o......r...F.c.
4f93 1e83 65e1 5a08 9c68 d619 0000 0000  O...e.Z..h......
0098 2051 fd1e 4ba7 44bb be68 0e1f ee14  .. Q..K.D..h....
677b a1a3 c354 0bf7 b1cd b606 e857 233e  g{...T.......W#>
0e61 bc66 49ff ff00 1d01 e362 9901 0100  .a.fI......b....
0000 0100 0000 0000 0000 0000 0000 0000  ................
0000 0000 0000 0000 0000 0000 0000 0000  ................
0000 00ff ffff ff07 04ff ff00 1d01 04ff  ................
ffff ff01 00f2 052a 0100 0000 4341 0496  .......*....CA..
"""


"""
    TransactionInput

Data Structure Storing Transaction Inputs
"""
struct TransactionInput
    # TODO: remove unlocking_script_size
    # the hash of the transaction where the output comes from
    hash                  :: UInt256
    output_index          :: UInt32
    unlocking_script_size :: UInt64
    unlocking_script      :: Vector{UInt8}
    sequence_number       :: UInt32
end

"""
    TransactionOutput

Data Structure Storing Transaction Outputs
"""
struct TransactionOutput
    # TODO: remove locking_script_size
    amount              :: UInt64 # in satoshis = 1e-8 bitcoins
    locking_script_size :: UInt64
    locking_script      :: Vector{UInt8}
end

"""
    Witness

Data Structure Storing The Witness for SegWit transactions
"""
struct Witness
    data :: Vector{Vector{UInt8}}
end

"""
    Transaction

Data Structure Storing Transactions

To get the hash of a transaction

```julia
double_sha256(tx)
```
"""
struct Transaction
    # TODO: remove *_counter
    version         :: UInt32
    marker          :: UInt8
    flag            :: UInt8
    input_counter   :: UInt64
    inputs          :: Vector{TransactionInput}
    output_counter  :: UInt64
    outputs         :: Vector{TransactionOutput}
    witness_counter :: UInt64
    witnesses       :: Vector{Witness}
    lock_time       :: UInt32
end

function TransactionInput(io)

    # TODO: Cannot read UInt256 directly from io here:
    in_hash = read!(io, Array{UInt256}(undef, 1))[1]
    # in_hash = read(io, UInt256)
    output_index = read(io, UInt32)
    unlocking_script_size = signed(read_varint(io))

    unlocking_script = read!(io, Array{UInt8}(undef, unlocking_script_size))
    sequence_number = read(io, UInt32)

    TransactionInput(
        in_hash,
        output_index,
        unlocking_script_size,
        unlocking_script,
        sequence_number
    )
end

function TransactionOutput(io)

    out_amount = read(io, UInt64)
    out_script_size = signed(read_varint(io))
    locking_script = read!(io, Array{UInt8}(undef, out_script_size))

    TransactionOutput(out_amount,
                      out_script_size,
                      locking_script)
end

function Witness(io::IO)
    n_items = read_varint(io)
    data = Vector{Vector{UInt8}}(undef, n_items)

    for i in 1:n_items
        l = read_varint(io)
        data[i] = read!(io, Array{UInt8, 1}(undef, l))
    end

    Witness(data)
end


function Transaction(io)

    version = read(io, UInt32)

    marker_or_n_in = read_varint(io)

    is_segwit = marker_or_n_in == zero(marker_or_n_in)
    if is_segwit
        marker = UInt8(marker_or_n_in)
        @assert marker == 0x00
        flag = read(io, UInt8)
        @assert flag == 0x01
        n_in = read_varint(io)
    else
        # these two don't matter
        marker = 0xff
        flag = 0xff
        n_in = marker_or_n_in
    end

    @assert n_in > 0
    inputs = TransactionInput[
        TransactionInput(io)
        for i in 1:n_in
    ]

    n_out = read_varint(io)
    @assert n_out > 0
    outputs = TransactionOutput[
        TransactionOutput(io)
        for i in 1:n_out
    ]

    if is_segwit
        n_witness = n_in
        @assert n_witness > 0
        witnesses = Witness[
            Witness(io)
            for i in 1:n_witness
        ]
    else
        n_witness = zero(UInt64)
        witnesses = Witness[]
    end

    locktime = read(io, UInt32)

    Transaction(version,
                marker,
                flag,
                n_in,
                inputs,
                n_out,
                outputs,
                n_witness,
                witnesses,
                locktime)
end

# TODO: is this the same as bytes2hex?
hexarray(x::Array{UInt8}) = mapreduce(x -> string(x, base = 16), *, x)

function showcompact(io::IO, input::TransactionInput)
    # TODO: do something useful here
    println(io, "")
end

function Base.show(io::IO, input::TransactionInput)
    if !get(io, :compact, false)
        println(io, "Transaction input:")
        println(io, "  Hash:                  " * string(input.hash,            base = 16))
        println(io, "  Output index:          " * string(input.output_index,    base = 10))
        println(io, "  Input Sequence:        " * string(input.sequence_number, base = 10))
    end
end

# function Base.showall(io::IO, input::TransactionInput)
#     println(io, "Transaction input:")
#     println(io, "  Hash:                  " * input.hash)
#     println(io, "  Output index:          " * input.output_index)
#     println(io, "  Unlocking script size: " * input.unlocking_script_size)
#     println(io, "  Unlocking script:      " * hexarray(input.unlocking_script))
#     println(io, "  Input Sequence:        " * input.sequence_number)
# end


function Base.show(io::IO, output::TransactionOutput)
    println(io, "Transaction output: " * string(output.amount, base = 10))
end
# function Base.showall(io::IO, output::TransactionOutput)
#     println(io, "Transaction output: "    * string(output.amount,              base = 10))
#     println(io, "  Locking script size: " * string(output.locking_script_size, base = 10))
#     println(io, "  Locking script:      " * hexarray(output.locking_script))
# end

function showcompact(io::IO, transaction::Transaction)
    # TODO: add id here
    println(io, "Transaction: ")
end

function Base.show(io::IO, transaction::Transaction)
    # TODO: add id here
    if !get(io, :compact, false)
        println(io, "Transaction: ")
        println(io, "  Version:        " * string(transaction.version, base = 10))
        println(io, "  Input counter:  " * string(transaction.input_counter, base = 10))
        println(io, "  Output counter: " * string(transaction.output_counter, base = 10))
        println(io, "  Lock time:      " * string(transaction.lock_time, base = 10))
    end
end

# function Base.showall(io::IO, transaction::Transaction)
#     # TODO: add id here
#     println(io, "Transaction: ")
#     println(io, "  Version:        " * string(transaction.version, base = 10))
#     println(io, "  Input counter:  " * string(transaction.input_counter, base = 10))
#     for i in 1:transaction.input_counter
#         show(transaction.inputs[i])
#     end
#     println(io, "  Output counter: " * string(transaction.output_counter, base = 10))
#     for i in 1:transaction.output_counter
#         show(transaction.outputs[i])
#     end
#     println(io, "  Lock time:      " * string(transaction.lock_time, base = 10))
# end

# TODO: little endian only:
function sha256(tx::Transaction)

    ctx = SHA.SHA256_CTX()

    SHA.update!(ctx, to_byte_tuple(tx.version))
    SHA.update!(ctx, to_varint(tx.input_counter))
    for i in 1:tx.input_counter
        SHA.update!(ctx, to_byte_tuple(tx.inputs[i].hash))
        SHA.update!(ctx, to_byte_tuple(tx.inputs[i].output_index))
        SHA.update!(ctx, to_varint(tx.inputs[i].unlocking_script_size))
        SHA.update!(ctx, tx.inputs[i].unlocking_script)
        SHA.update!(ctx, to_byte_tuple(tx.inputs[i].sequence_number))
    end
    SHA.update!(ctx, to_varint(tx.output_counter))
    for i in 1:tx.output_counter
        SHA.update!(ctx, to_byte_tuple(tx.outputs[i].amount))
        SHA.update!(ctx, to_varint(tx.outputs[i].locking_script_size))
        SHA.update!(ctx, tx.outputs[i].locking_script)
    end
    SHA.update!(ctx, to_byte_tuple(tx.lock_time))

    return SHA.digest!(ctx)
end

function double_sha256(tx::Transaction)::UInt256
    tx |> sha256 |> sha256 |> x -> reinterpret(UInt256, x)[1]
end

# TODO: copyto! is save, right?
# TODO: find an allocation free version for these: copyto!(x, i, to_byte_tuple(y))
"""
mutates data in place, advances idx and returns it.
"""
function dump_txin_data!(data, idx, txin::TransactionInput)
    copyto!(data, idx, to_byte_tuple(txin.hash))
    idx += sizeof(txin.hash)

    copyto!(data, idx, to_byte_tuple(txin.output_index))
    idx += sizeof(txin.output_index)

    unlocking_script_size = to_varint(txin.unlocking_script_size)
    copyto!(data, idx, unlocking_script_size)
    idx += sizeof(unlocking_script_size)

    copyto!(data, idx, txin.unlocking_script)
    idx += sizeof(txin.unlocking_script)

    copyto!(data, idx, to_byte_tuple(txin.sequence_number))
    idx += sizeof(txin.sequence_number)

    return idx
end

# TODO: copyto! is save, right?
# TODO: find an allocation free version for these: copyto!(x, i, to_byte_tuple(y))
"""
mutates data in place, advances idx and returns it.
"""
function dump_txout_data!(data, idx, txout::TransactionOutput)
    copyto!(data, idx, to_byte_tuple(txout.amount))
    idx += sizeof(txout.amount)

    locking_script_size = to_varint(txout.locking_script_size)
    copyto!(data, idx, locking_script_size)
    idx += sizeof(locking_script_size)

    copyto!(data, idx, txout.locking_script)
    idx += sizeof(txout.locking_script)

    return idx
end

# TODO: copyto! is save, right?
# TODO: find an allocation free version for these: copyto!(x, i, to_byte_tuple(y))
"""
mutates data in place, advances idx and returns it.
"""
function dump_tx_data!(data, idx, tx::Transaction)
    copyto!(data, idx, to_byte_tuple(tx.version))
    idx += sizeof(tx.version)

    is_segwit = tx.marker == 0x00
    if is_segwit
        data[idx] = tx.marker
        idx += 1
        data[idx] = tx.flag
        idx += 1
    end

    input_counter = to_varint(tx.input_counter)
    copyto!(data, idx, input_counter)
    idx += sizeof(input_counter)
    for i in 1:tx.input_counter
        idx = dump_txin_data!(data, idx, tx.inputs[i])
    end

    output_counter = to_varint(tx.output_counter)
    copyto!(data, idx, output_counter)
    idx += sizeof(output_counter)
    for i in 1:tx.output_counter
        idx = dump_txout_data!(data, idx, tx.outputs[i])
    end

    if is_segwit
        for i in 1:tx.input_counter
            n_items = length(tx.witnesses[i].data)
            n_items_bytes = to_varint(n_items)
            copyto!(data, idx, n_items_bytes)
            idx += length(n_items_bytes)

            for j in 1:n_items
                l = length(tx.witnesses[i].data[j])
                l_bytes = to_varint(l)
                copyto!(data, idx, l_bytes)
                idx += length(l_bytes)

                copyto!(data, idx, tx.witnesses[i].data[j])
                idx += l
            end
        end
    end

    copyto!(data, idx, to_byte_tuple(tx.lock_time))
    idx += sizeof(tx.lock_time)

    return idx
end

# TODO: common abstraction with "Link"?
struct FilePointer
    file_number   :: UInt64
    file_position :: UInt64
end

function Transaction(fp::FilePointer)
    fp.file_number |>
        get_block_chain_file_path |>
        x -> open(x) do fh
            seek(fh, fp.file_position)
            Transaction(fh)
        end
end

total_output(tx::Transaction) = sum(x -> x.amount, tx.outputs)

is_coinbase(txin::TransactionInput) = txin.hash == zero(UInt256)
