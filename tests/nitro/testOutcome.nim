import std/unittest
import pkg/nimcrypto
import pkg/nitro/outcome
import ./examples

suite "outcome":

  test "encodes guarantees":
    let guarantee = Guarantee.example
    var writer: AbiWriter
    writer.startTuple()
    writer.write(guarantee.targetChannelId)
    writer.write(guarantee.destinations)
    writer.finishTuple()
    check Abi.encode(guarantee) == writer.finish()

  test "encodes allocation items":
    let item = AllocationItem.example
    var writer: AbiWriter
    writer.startTuple()
    writer.write(item.destination)
    writer.write(item.amount)
    writer.finishTuple()
    check Abi.encode(item) == writer.finish()

  test "encodes allocation outcome":
    let assetOutcome = AssetOutcome(
      kind: allocationType,
      assetHolder: EthAddress.example,
      allocation: Allocation.example
    )
    var content: AbiWriter
    content.startTuple()
    content.write(allocationType)
    content.write(Abi.encode(assetOutcome.allocation))
    content.finishTuple()
    var writer: AbiWriter
    writer.startTuple()
    writer.write(assetOutcome.assetHolder)
    writer.write(content.finish())
    writer.finishTuple()
    check Abi.encode(assetOutcome) == writer.finish()

  test "encodes guarantee outcome":
    let assetOutcome = AssetOutcome(
      kind: guaranteeType,
      assetHolder: EthAddress.example,
      guarantee: Guarantee.example
    )
    var content: AbiWriter
    content.startTuple()
    content.write(guaranteeType)
    content.write(Abi.encode(assetOutcome.guarantee))
    content.finishTuple()
    var writer: AbiWriter
    writer.startTuple()
    writer.write(assetOutcome.assetHolder)
    writer.write(content.finish())
    writer.finishTuple()
    check Abi.encode(assetOutcome) == writer.finish()

  test "encodes outcomes":
    let outcome = Outcome.example()
    var writer: AbiWriter
    writer.startTuple()
    writer.write(seq[AssetOutcome](outcome))
    writer.finishTuple()
    check Abi.encode(outcome) == writer.finish()

  test "hashes outcomes":
    let outcome = Outcome.example
    let encoded = Abi.encode(outcome)
    let hashed = keccak256.digest(encoded).data
    check hashOutcome(outcome) == hashed
