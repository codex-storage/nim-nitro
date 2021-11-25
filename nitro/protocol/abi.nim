import pkg/contractabi
import ../basics

push: {.upraises:[].}

export basics
export contractabi

func encode*(encoder: var AbiEncoder, address: EthAddress) =
  var padded: array[32, byte]
  padded[12..<32] = address.toArray
  encoder.write(padded)

func encode*(encoder: var AbiEncoder, destination: Destination) =
  encoder.write(destination.toArray)
