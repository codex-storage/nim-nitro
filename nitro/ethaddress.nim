import pkg/questionable
import pkg/questionable/results
import pkg/stew/byteutils

export questionable

type EthAddress* = distinct array[20, byte]

proc zero*(_: type EthAddress): EthAddress =
  EthAddress.default

proc toArray*(address: EthAddress): array[20, byte] =
  array[20, byte](address)

proc `$`*(a: EthAddress): string =
  a.toArray().toHex()

proc parse*(_: type EthAddress, hex: string): ?EthAddress =
  EthAddress(array[20, byte].fromHex(hex)).catch.option

proc `==`*(a, b: EthAddress): bool {.borrow.}
