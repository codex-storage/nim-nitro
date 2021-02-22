import std/math
import pkg/stint

export stint

type
  UInt48* = range[0'u64..2'u64^48-1]
  EthAddress* = array[20, byte]
