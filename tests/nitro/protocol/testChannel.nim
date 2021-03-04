import std/unittest
import pkg/nitro/protocol/channel
import pkg/nitro/protocol/abi
import pkg/nimcrypto
import pkg/stew/byteutils
import ./examples

suite "channel":

  let channel = Channel.example

  test "calculates channel id":
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(channel.chainId)
    encoder.write(channel.participants)
    encoder.write(channel.nonce)
    encoder.finishTuple()
    let encoded = encoder.finish()
    let hashed = keccak256.digest(encoded).data
    check getChannelId(channel) == hashed

  test "produces same id as javascript implementation":
    let channel = Channel(
      chainId: 9001.u256,
      nonce: 1,
      participants: @[
        EthAddress.fromHex("24b905Dcc8A11C0FE57C2592f3D25f0447402C10").get()
      ]
    )
    let expected = array[32, byte].fromHex(
      "4f8cce57e9fe88edaab05234972eaf0c2d183e4f6b175aff293375fbe4d5d7cc"
    )
    check getChannelId(channel) == expected
