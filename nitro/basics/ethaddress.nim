import std/hashes
import pkg/questionable
import pkg/questionable/results
import pkg/stew/byteutils

export questionable

type EthAddress* = distinct array[20, byte]

func zero*(_: type EthAddress): EthAddress =
  EthAddress.default

func toArray*(address: EthAddress): array[20, byte] =
  array[20, byte](address)

func `$`*(a: EthAddress): string =
  a.toArray().toHex()

func parse*(_: type EthAddress, hex: string): ?EthAddress =
  EthAddress(array[20, byte].fromHex(hex)).catch.option

proc `==`*(a, b: EthAddress): bool {.borrow.}
proc `hash`*(a: EthAddress): Hash {.borrow.}
