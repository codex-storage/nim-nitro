import pkg/nitro/protocol/abi
import pkg/nimcrypto
import ../basics

suite "channel definition":

  let channel = ChannelDefinition.example

  test "calculates channel id":
    let encoded = AbiEncoder.encode:
      (channel.chainId, channel.participants, channel.nonce)
    let hashed = keccak256.digest(encoded).data
    check getChannelId(channel) == Destination(hashed)

  test "produces same id as javascript implementation":
    let channel = ChannelDefinition(
      chainId: 9001.u256,
      nonce: 1,
      participants: @[
        !EthAddress.init("24b905Dcc8A11C0FE57C2592f3D25f0447402C10")
      ]
    )
    let expected = !Destination.parse(
      "4f8cce57e9fe88edaab05234972eaf0c2d183e4f6b175aff293375fbe4d5d7cc"
    )
    check getChannelId(channel) == expected
