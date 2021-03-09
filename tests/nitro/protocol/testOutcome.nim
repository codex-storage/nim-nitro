import pkg/nitro/protocol/abi
import pkg/nimcrypto
import ../basics

suite "outcome":

  test "encodes guarantees":
    let guarantee = Guarantee.example
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.startTuple()
    encoder.write(guarantee.targetChannelId)
    encoder.write(guarantee.destinations)
    encoder.finishTuple()
    encoder.finishTuple()
    check AbiEncoder.encode(guarantee) == encoder.finish()

  test "encodes allocation items":
    let item = AllocationItem.example
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(item.destination)
    encoder.write(item.amount)
    encoder.finishTuple()
    check AbiEncoder.encode(item) == encoder.finish()

  test "encodes allocation":
    let allocation = Allocation.example
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(seq[AllocationItem](allocation))
    encoder.finishTuple()
    check AbiEncoder.encode(allocation) == encoder.finish()

  test "encodes allocation outcome":
    let assetOutcome = AssetOutcome(
      kind: allocationType,
      assetHolder: EthAddress.example,
      allocation: Allocation.example
    )
    var content= AbiEncoder.init()
    content.startTuple()
    content.startTuple()
    content.write(allocationType)
    content.write(AbiEncoder.encode(assetOutcome.allocation))
    content.finishTuple()
    content.finishTuple()
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(assetOutcome.assetHolder)
    encoder.write(content.finish())
    encoder.finishTuple()
    check AbiEncoder.encode(assetOutcome) == encoder.finish()

  test "encodes guarantee outcome":
    let assetOutcome = AssetOutcome(
      kind: guaranteeType,
      assetHolder: EthAddress.example,
      guarantee: Guarantee.example
    )
    var content= AbiEncoder.init()
    content.startTuple()
    content.startTuple()
    content.write(guaranteeType)
    content.write(AbiEncoder.encode(assetOutcome.guarantee))
    content.finishTuple()
    content.finishTuple()
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(assetOutcome.assetHolder)
    encoder.write(content.finish())
    encoder.finishTuple()
    check AbiEncoder.encode(assetOutcome) == encoder.finish()

  test "encodes outcomes":
    let outcome = Outcome.example()
    var encoder= AbiEncoder.init()
    encoder.startTuple()
    encoder.write(seq[AssetOutcome](outcome))
    encoder.finishTuple()
    check AbiEncoder.encode(outcome) == encoder.finish()

  test "hashes outcomes":
    let outcome = Outcome.example
    let encoded = AbiEncoder.encode(outcome)
    let hashed = keccak256.digest(encoded).data
    check hashOutcome(outcome) == hashed

  test "produces the same encoding as the javascript implementation":
    let outcome = Outcome(@[
      AssetOutcome(
        kind: allocationType,
        assetHolder: EthAddress.parse(
          "1E90B49563da16D2537CA1Ddd9b1285279103D93"
        ).get(),
        allocation: Allocation(@[
          (
            destination: Destination.parse(
              "f1918e8562236eb17adc8502332f4c9c82bc14e19bfc0aa10ab674ff75b3d2f3"
            ).get(),
            amount: 0x05.u256
          )
        ])
      ),
      AssetOutcome(
        kind: guaranteeType,
        assetHolder: EthAddress.parse(
          "1E90B49563da16D2537CA1Ddd9b1285279103D93"
        ).get(),
        guarantee: Guarantee(
          targetChannelId: Destination.parse(
            "cac1bb71f0a97c8ac94ca9546b43178a9ad254c7b757ac07433aa6df35cd8089"
          ).get(),
          destinations: @[
            Destination.parse(
              "f1918e8562236eb17adc8502332f4c9c82bc14e19bfc0aa10ab674ff75b3d2f3"
            ).get()
          ]
        )
      )
    ])
    let expected = fromHex(
      "53993a1bc1de832c2e04bd59491a18d43b6546ec5c611f13dc5dc56d678d228d"
    )
    check hashOutcome(outcome) == expected
