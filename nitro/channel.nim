import pkg/nimcrypto
import ./abi
import ./types

include ./noerrors

export types

type
  Channel* = object
    nonce*: UInt48
    participants*: seq[EthAddress]
    chainId*: UInt256

proc getChannelId*(channel: Channel): array[32, byte] =
  var encoder= AbiEncoder.init()
  encoder.startTuple()
  encoder.write(channel.chainId)
  encoder.write(channel.participants)
  encoder.write(channel.nonce)
  encoder.finishTuple()
  keccak256.digest(encoder.finish()).data
