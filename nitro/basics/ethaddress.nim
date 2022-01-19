import std/hashes
import pkg/contractabi/address

export address

type EthAddress* = Address

func zero*(_: type EthAddress): EthAddress =
  EthAddress.default

proc `hash`*(a: EthAddress): Hash =
  hash(a.toArray)
