import std/unittest
import pkg/nitro/abi
import pkg/nitro/types
import pkg/stint
import ./examples

suite "ABI encoding":

  proc zeroes(amount: int): seq[byte] =
    newSeq[byte](amount)

  test "encodes uint8":
    check Abi.encode(42'u8) == 31.zeroes & 42'u8

  test "encodes booleans":
    check Abi.encode(false) == 31.zeroes & 0'u8
    check Abi.encode(true) == 31.zeroes & 1'u8

  test "encodes uint16, 32, 64":
    check Abi.encode(0xABCD'u16) ==
      30.zeroes & 0xAB'u8 & 0xCD'u8
    check Abi.encode(0x11223344'u32) ==
      28.zeroes & 0x11'u8 & 0x22'u8 & 0x33'u8 & 0x44'u8
    check Abi.encode(0x1122334455667788'u64) ==
      24.zeroes &
      0x11'u8 & 0x22'u8 & 0x33'u8 & 0x44'u8 &
      0x55'u8 & 0x66'u8 & 0x77'u8 & 0x88'u8

  test "encodes ranges":
    type SomeRange = range[0x0000'u16..0xAAAA'u16]
    check Abi.encode(SomeRange(0x1122)) == 30.zeroes & 0x11'u8 & 0x22'u8

  test "encodes enums":
    type SomeEnum = enum
      one = 1
      two = 2
    check Abi.encode(one) == 31.zeroes & 1'u8
    check Abi.encode(two) == 31.zeroes & 2'u8

  test "encodes stints":
    let uint256 = UInt256.example
    check Abi.encode(uint256) == @(uint256.toBytesBE)
    let uint128 = UInt128.example
    check Abi.encode(uint128) == 16.zeroes & @(uint128.toBytesBE)

  test "encodes byte arrays":
    let bytes3 = [1'u8, 2'u8, 3'u8]
    check Abi.encode(bytes3) == @bytes3 & 29.zeroes
    let bytes32 = array[32, byte].example
    check Abi.encode(bytes32) == @bytes32
    let bytes33 = array[33, byte].example
    check Abi.encode(bytes33) == @bytes33 & 31.zeroes

  test "encodes byte sequences":
    let bytes3 = @[1'u8, 2'u8, 3'u8]
    let bytes3len = Abi.encode(bytes3.len.uint64)
    check Abi.encode(bytes3) == bytes3len & bytes3 & 29.zeroes
    let bytes32 = @(array[32, byte].example)
    let bytes32len = Abi.encode(bytes32.len.uint64)
    check Abi.encode(bytes32) == bytes32len & bytes32
    let bytes33 = @(array[33, byte].example)
    let bytes33len = Abi.encode(bytes33.len.uint64)
    check Abi.encode(bytes33) == bytes33len & bytes33 & 31.zeroes

  test "encodes ethereum addresses":
    let address = EthAddress.example
    check Abi.encode(address) == 12.zeroes & @(address.toArray)

  test "encodes tuples":
    let a = true
    let b = @[1'u8, 2'u8, 3'u8]
    let c = 0xAABBCCDD'u32
    let d = @[4'u8, 5'u8, 6'u8]
    var writer: AbiWriter
    writer.startTuple()
    writer.write(a)
    writer.write(b)
    writer.write(c)
    writer.write(d)
    writer.finishTuple()
    check writer.finish() ==
      Abi.encode(a) &
      Abi.encode(4 * 32'u8) & # offset from start of tuple
      Abi.encode(c) &
      Abi.encode(6 * 32'u8) & # offset from start of tuple
      Abi.encode(b) &
      Abi.encode(d)

  test "encodes nested tuples":
    let a = true
    let b = @[1'u8, 2'u8, 3'u8]
    let c = 0xAABBCCDD'u32
    let d = @[4'u8, 5'u8, 6'u8]
    var writer: AbiWriter
    writer.startTuple()
    writer.write(a)
    writer.write(b)
    writer.startTuple()
    writer.write(c)
    writer.write(d)
    writer.finishTuple()
    writer.finishTuple()
    check writer.finish() ==
      Abi.encode(a) &
      Abi.encode(6 * 32'u8) & # offset from start of tuple
      Abi.encode(c) &
      Abi.encode(2 * 32'u8) & # offset from start of tuple
      Abi.encode(d) &
      Abi.encode(b)

  test "encodes arrays":
    let element1 = seq[byte].example
    let element2 = seq[byte].example
    var expected: AbiWriter
    expected.startTuple()
    expected.write(element1)
    expected.write(element2)
    expected.finishTuple()
    check Abi.encode([element1, element2]) == expected.finish()

  test "encodes sequences":
    let element1 = seq[byte].example
    let element2 = seq[byte].example
    var expected: AbiWriter
    expected.write(2'u8)
    expected.startTuple()
    expected.write(element1)
    expected.write(element2)
    expected.finishTuple()
    check Abi.encode(@[element1, element2]) == expected.finish()

  test "encodes sequence as dynamic element":
    let s = @[42.u256, 43.u256]
    var writer: AbiWriter
    writer.startTuple()
    writer.write(s)
    writer.finishTuple()
    check writer.finish() ==
      Abi.encode(32'u8) & # offset from start of tuple
      Abi.encode(s)

  test "encodes array of static elements as static element":
    let a = [[42'u8], [43'u8]]
    var writer: AbiWriter
    writer.startTuple()
    writer.write(a)
    writer.finishTuple()
    check writer.finish() == Abi.encode(a)

  test "encodes array of dynamic elements as dynamic element":
    let a = [@[42'u8], @[43'u8]]
    var writer: AbiWriter
    writer.startTuple()
    writer.write(a)
    writer.finishTuple()
    check writer.finish() ==
      Abi.encode(32'u8) & # offset from start of tuple
      Abi.encode(a)

# https://medium.com/b2expand/abi-encoding-explanation-4f470927092d
# https://docs.soliditylang.org/en/v0.8.1/abi-spec.html#formal-specification-of-the-encoding
