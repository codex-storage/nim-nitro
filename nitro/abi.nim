import pkg/stew/endians2
import pkg/stint
import ./types

type
  Abi* = object
  AbiWriter* = object
    bytes: seq[byte]
    tuples: seq[Tuple]
  Tuple = object
    start: int
    postponed: seq[Split]
  Split = object
    head: Slice[int]
    tail: seq[byte]

proc isStatic*(_: type Abi, t: type SomeUnsignedInt): bool = true
proc isStatic*(_: type Abi, t: type StUint): bool = true
proc isStatic*(_: type Abi, t: type bool): bool = true
proc isStatic*(_: type Abi, t: type enum): bool = true
proc isStatic*[T](_: type Abi, t: type seq[T]): bool = false
proc isStatic*[I, T](_: type Abi, t: type array[I, T]): bool = Abi.isStatic(T)

proc encode*[T](_: type Abi, value: T): seq[byte]

proc pad(writer: var AbiWriter, len: int) =
  let padlen = (32 - len mod 32) mod 32
  for _ in 0..<padlen:
    writer.bytes.add(0'u8)

proc padleft(writer: var AbiWriter, bytes: openArray[byte]) =
  writer.pad(bytes.len)
  writer.bytes.add(bytes)

proc padright(writer: var AbiWriter, bytes: openArray[byte]) =
  writer.bytes.add(bytes)
  writer.pad(bytes.len)

proc write*(writer: var AbiWriter, value: SomeUnsignedInt | StUint) =
  writer.padleft(value.toBytesBE)

proc write*(writer: var AbiWriter, value: bool) =
  writer.write(cast[uint8](value))

proc write*(writer: var AbiWriter, value: enum) =
  writer.write(uint64(ord(value)))

proc write*[I](writer: var AbiWriter, bytes: array[I, byte]) =
  writer.padright(bytes)

proc writeLater[T](writer: var AbiWriter, value: T) =
  var split: Split
  split.head.a = writer.bytes.high + 1
  writer.write(0'u64)
  split.head.b = writer.bytes.high
  split.tail = Abi.encode(value)
  writer.tuples[^1].postponed.add(split)

proc write*(writer: var AbiWriter, bytes: seq[byte]) =
  if writer.tuples.len == 0:
    writer.write(bytes.len.uint64)
    writer.padright(bytes)
  else:
    writer.writeLater(bytes)

proc write*(writer: var AbiWriter, address: EthAddress) =
  writer.padleft(address.toArray)

proc startTuple*(writer: var AbiWriter) =
  writer.tuples.add(Tuple(start: writer.bytes.len))

proc finishTuple*(writer: var AbiWriter) =
  let tupl = writer.tuples.pop()
  for split in tupl.postponed:
    let offset = writer.bytes.len - tupl.start
    writer.bytes[split.head] = Abi.encode(offset.uint64)
    writer.bytes.add(split.tail)

proc write*[I, T](writer: var AbiWriter, value: array[I, T]) =
  if writer.tuples.len == 0 or Abi.isStatic(T):
    writer.startTuple()
    for element in value:
      writer.write(element)
    writer.finishTuple()
  else:
    writer.writeLater(value)

proc write*[T](writer: var AbiWriter, value: seq[T]) =
  if writer.tuples.len == 0:
    writer.write(value.len.uint64)
    writer.startTuple()
    for element in value:
      writer.write(element)
    writer.finishTuple()
  else:
    writer.writeLater(value)

proc finish*(writer: var AbiWriter): seq[byte] =
  doAssert writer.tuples.len == 0, "not all tuples were finished"
  doAssert writer.bytes.len mod 32 == 0, "encoding invariant broken"
  writer.bytes

proc encode*[T](_: type Abi, value: T): seq[byte] =
  var writer: AbiWriter
  writer.write(value)
  writer.finish()
