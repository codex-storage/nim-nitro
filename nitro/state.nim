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

{.push raises:[].}

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
    outcome: AbiEncoder.encode(state.outcome),
    appData: state.appData
  )

proc hashAppPart*(state: State): array[32, byte] =
  var encoder= AbiEncoder.init()
  encoder.startTuple()
  encoder.write(state.challengeDuration)
  encoder.write(state.appDefinition)
  encoder.write(state.appData)
  encoder.finishTuple()
  keccak256.digest(encoder.finish).data

proc hashState*(state: State): array[32, byte] =
  var encoder= AbiEncoder.init()
  encoder.startTuple()
  encoder.write(state.turnNum)
  encoder.write(state.isFinal)
  encoder.write(getChannelId(state.channel))
  encoder.write(hashAppPart(state))
  encoder.write(hashOutcome(state.outcome))
  encoder.finishTuple()
  keccak256.digest(encoder.finish).data
