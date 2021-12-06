import pkg/nitro/protocol/abi
import ../basics

suite "ABI encoding":

  proc zeroes(amount: int): seq[byte] =
    newSeq[byte](amount)

  test "encodes ethereum addresses":
    let address = EthAddress.example
    check AbiEncoder.encode(address) == 12.zeroes & @(address.toArray)

  test "encodes nitro destinations":
    let destination = Destination.example
    check:
      AbiEncoder.encode(destination) == AbiEncoder.encode(destination.toArray)
