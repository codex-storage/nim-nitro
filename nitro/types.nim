import std/math
import pkg/stint

export stint

type
  UInt48* = range[0'u64..2'u64^48-1]
  EthAddress* = distinct array[20, byte]

proc toArray*(address: EthAddress): array[20, byte] =
  array[20, byte](address)

proc `==`*(a, b: EthAddress): bool {.borrow.}
