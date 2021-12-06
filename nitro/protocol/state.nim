import pkg/nimcrypto
import ../basics
import ./channel
import ./outcome
import ./abi

push: {.upraises:[].}

export basics
export channel
export outcome

type
  State* = object
    turnNum*: UInt48
    isFinal*: bool
    channel*: ChannelDefinition
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

func fixedPart*(state: State): FixedPart =
  FixedPart(
    chainId: state.channel.chainId,
    participants: state.channel.participants,
    channelNonce: state.channel.nonce,
    appDefinition: state.appDefinition,
    challengeDuration: state.challengeDuration
  )

func variablePart*(state: State): VariablePart =
  VariablePart(
    outcome: AbiEncoder.encode(state.outcome),
    appData: state.appData
  )

func hashAppPart*(state: State): array[32, byte] =
  let encoding = AbiEncoder.encode:
    (state.challengeDuration, state.appDefinition, state.appData)
  keccak256.digest(encoding).data

func hashState*(state: State): array[32, byte] =
  let encoding = AbiEncoder.encode:
    (
      state.turnNum,
      state.isFinal,
      getChannelId(state.channel),
      hashAppPart(state),
      hashOutcome(state.outcome)
    )
  keccak256.digest(encoding).data
