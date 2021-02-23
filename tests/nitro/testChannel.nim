import std/unittest
import pkg/nitro/channel
import pkg/nitro/abi
import pkg/nimcrypto
import ./examples

suite "channel":

  let channel = Channel.example

  test "calculates channel id":
    var writer: AbiWriter
    writer.startTuple()
    writer.write(channel.chainId)
    writer.write(channel.participants)
    writer.write(channel.nonce)
    writer.finishTuple()
    let encoded = writer.finish()
    let hashed = keccak256.digest(encoded).data
    check getChannelId(channel) == hashed

