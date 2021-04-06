import pkg/nimcrypto
import ../basics
import ./abi

push: {.upraises:[].}

export basics

type
  ChannelDefinition* = object
    nonce*: UInt48
    participants*: seq[EthAddress]
    chainId*: UInt256

func getChannelId*(channel: ChannelDefinition): Destination =
  var encoder= AbiEncoder.init()
  encoder.startTuple()
  encoder.write(channel.chainId)
  encoder.write(channel.participants)
  encoder.write(channel.nonce)
  encoder.finishTuple()
  Destination(keccak256.digest(encoder.finish()).data)
