import pkg/questionable
import pkg/questionable/results
import pkg/stew/byteutils
import ./ethaddress

include questionable/errorban

type Destination* = distinct array[32, byte]

proc toArray*(destination: Destination): array[32, byte] =
  array[32, byte](destination)

proc `$`*(destination: Destination): string =
  destination.toArray().toHex()

proc parse*(_: type Destination, s: string): ?Destination =
   Destination(array[32, byte].fromHex(s)).catch.option

proc `==`*(a, b: Destination): bool {.borrow.}

proc toDestination*(address: EthAddress): Destination =
  var bytes: array[32, byte]
  for i in 0..<20:
    bytes[12 + i] = array[20, byte](address)[i]
  Destination(bytes)
