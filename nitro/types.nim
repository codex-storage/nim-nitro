import std/math
import pkg/questionable
import pkg/stint
import pkg/stew/byteutils

include questionable/errorban

export stint
export questionable

type
  UInt48* = range[0'u64..2'u64^48-1]
  EthAddress* = distinct array[20, byte]

proc toArray*(address: EthAddress): array[20, byte] =
  array[20, byte](address)

proc fromHex*(_: type EthAddress, hex: string): ?EthAddress =
  try:
    EthAddress(array[20, byte].fromHex(hex)).some
  except ValueError:
    EthAddress.none

proc `==`*(a, b: EthAddress): bool {.borrow.}
