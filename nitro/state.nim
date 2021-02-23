import pkg/nimcrypto
import ./types
import ./channel
import ./outcome
import ./abi

export types
export channel
export outcome

type
  State* = object
    turnNum*: UInt48
    isFinal*: bool
    channel*: Channel
    challengeDuration*: UInt48
    outcome*: Outcome
    appDefinition*: EthAddress
    appData*: seq[byte]
  FixedPart* = object
    chainId*: UInt256
    participants*: seq[EthAddress]
    channelNonce*: UInt48
    appDefinition*: EthAddress
    challengeDuration*: UInt48
  VariablePart* = object
    outcome*: seq[byte]
    appdata*: seq[byte]

proc fixedPart*(state: State): FixedPart =
  FixedPart(
    chainId: state.channel.chainId,
    participants: state.channel.participants,
    channelNonce: state.channel.nonce,
    appDefinition: state.appDefinition,
    challengeDuration: state.challengeDuration
  )

proc variablePart*(state: State): VariablePart =
  VariablePart(
    outcome: Abi.encode(state.outcome),
    appData: state.appData
  )

proc hashAppPart*(state: State): array[32, byte] =
  var writer: AbiWriter
  writer.startTuple()
  writer.write(state.challengeDuration)
  writer.write(state.appDefinition)
  writer.write(state.appData)
  writer.finishTuple()
  keccak256.digest(writer.finish).data

proc hashState*(state: State): array[32, byte] =
  var writer: AbiWriter
  writer.startTuple()
  writer.write(state.turnNum)
  writer.write(state.isFinal)
  writer.write(getChannelId(state.channel))
  writer.write(hashAppPart(state))
  writer.write(hashOutcome(state.outcome))
  writer.finishTuple()
  keccak256.digest(writer.finish).data
