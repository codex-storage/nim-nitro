import pkg/nitro/protocol/abi
import pkg/nimcrypto
import pkg/stew/byteutils
import ../basics

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
      outcome: AbiEncoder.encode(state.outcome),
      appData: state.appData
    )

  test "hashes app part of state":
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(state.challengeDuration)
    encoder.write(state.appDefinition)
    encoder.write(state.appData)
    encoder.finishTuple()
    let encoded = encoder.finish()
    let hashed = keccak256.digest(encoded).data
    check hashAppPart(state) == hashed

  test "hashes state":
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(state.turnNum)
    encoder.write(state.isFinal)
    encoder.write(getChannelId(state.channel))
    encoder.write(hashAppPart(state))
    encoder.write(hashOutcome(state.outcome))
    encoder.finishTuple()
    let encoded = encoder.finish()
    let hashed = keccak256.digest(encoded).data
    check hashState(state) == hashed

  test "produces the same hash as the javascript implementation":
    let state = State(
      channel: ChannelDefinition(
        chainId: 0x1.u256,
        nonce: 1,
        participants: @[
          !EthAddress.parse("DBE821484648c73C1996Da25f2355342B9803eBD")
        ]
      ),
      outcome: Outcome(@[]),
      turnNum: 1,
      isFinal: false,
      appData: @[0'u8],
      appDefinition: EthAddress.default,
      challengeDuration: 5
    )
    let expected = array[32, byte].fromHex(
      "8f515b04e6120bffadc159b5e117297bb7c135337d4ec9c0468bcf298292f46d"
    )
    check hashState(state) == expected
