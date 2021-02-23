import pkg/nimcrypto
import ./abi
import ./types

export types

type
  Channel* = object
    nonce*: UInt48
    participants*: seq[EthAddress]
    chainId*: UInt256

proc getChannelId*(channel: Channel): array[32, byte] =
  var writer: AbiWriter
  writer.startTuple()
  writer.write(channel.chainId)
  writer.write(channel.participants)
  writer.write(channel.nonce)
  writer.finishTuple()
  keccak256.digest(writer.finish()).data
