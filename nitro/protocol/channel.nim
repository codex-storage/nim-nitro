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
  let encoding = AbiEncoder.encode:
     (channel.chainId, channel.participants, channel.nonce)
  Destination(keccak256.digest(encoding).data)
