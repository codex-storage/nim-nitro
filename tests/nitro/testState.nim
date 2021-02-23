import std/unittest
import pkg/nimcrypto
import pkg/nitro
import pkg/nitro/state
import pkg/nitro/abi
import ./examples

suite "state":

  let state = State.example

  test "has a fixed part":
    check state.fixedPart == FixedPart(
      chainId: state.channel.chainId,
      participants: state.channel.participants,
      channelNonce: state.channel.nonce,
      appDefinition: state.appDefinition,
      challengeDuration: state.challengeDuration
    )

  test "has a variable part":
    check state.variablePart == VariablePart(
      outcome: Abi.encode(state.outcome),
      appData: state.appData
    )

  test "hashes app part of state":
    var writer: AbiWriter
    writer.startTuple()
    writer.write(state.challengeDuration)
    writer.write(state.appDefinition)
    writer.write(state.appData)
    writer.finishTuple()
    let encoded = writer.finish()
    let hashed = keccak256.digest(encoded).data
    check hashAppPart(state) == hashed

  test "hashes state":
    var writer: AbiWriter
    writer.startTuple()
    writer.write(state.turnNum)
    writer.write(state.isFinal)
    writer.write(getChannelId(state.channel))
    writer.write(hashAppPart(state))
    writer.write(hashOutcome(state.outcome))
    writer.finishTuple()
    let encoded = writer.finish()
    let hashed = keccak256.digest(encoded).data
    check hashState(state) == hashed

