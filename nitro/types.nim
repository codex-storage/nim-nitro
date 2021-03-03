import std/math
import std/options
import pkg/stint
import pkg/stew/byteutils

export stint
export options

type
  UInt48* = range[0'u64..2'u64^48-1]
  EthAddress* = distinct array[20, byte]

{.push raises:[].}

proc toArray*(address: EthAddress): array[20, byte] =
  array[20, byte](address)

proc fromHex*(_: type EthAddress, hex: string): Option[EthAddress] =
  try:
    EthAddress(array[20, byte].fromHex(hex)).some
  except ValueError:
    EthAddress.none

proc `==`*(a, b: EthAddress): bool {.borrow.}
