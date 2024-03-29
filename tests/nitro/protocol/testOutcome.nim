import pkg/nitro/protocol/abi
import pkg/nimcrypto
import ../basics

suite "outcome":

  test "encodes guarantees":
    let guarantee = Guarantee.example
    let expected = AbiEncoder.encode:
      ((guarantee.targetChannelId, guarantee.destinations),)
    check AbiEncoder.encode(guarantee) == expected

  test "encodes allocation items":
    let item = AllocationItem.example
    let expected = AbiEncoder.encode: (item.destination, item.amount)
    check AbiEncoder.encode(item) == expected

  test "encodes allocation":
    let allocation = Allocation.example
    let expected = AbiEncoder.encode:
      (seq[AllocationItem](allocation),)
    check AbiEncoder.encode(allocation) == expected

  test "encodes allocation outcome":
    let assetOutcome = AssetOutcome(
      kind: allocationType,
      assetHolder: EthAddress.example,
      allocation: Allocation.example
    )
    let content = AbiEncoder.encode:
      ((allocationType, AbiEncoder.encode(assetOutcome.allocation)),)
    let expected = AbiEncoder.encode:
      (assetOutcome.assetHolder, content)
    check AbiEncoder.encode(assetOutcome) == expected

  test "encodes guarantee outcome":
    let assetOutcome = AssetOutcome(
      kind: guaranteeType,
      assetHolder: EthAddress.example,
      guarantee: Guarantee.example
    )
    let content = AbiEncoder.encode:
      ((guaranteeType, AbiEncoder.encode(assetOutcome.guarantee)),)
    let expected = AbiEncoder.encode:
      (assetOutcome.assetHolder, content)
    check AbiEncoder.encode(assetOutcome) == expected

  test "encodes outcomes":
    let outcome = Outcome.example()
    let expected = AbiEncoder.encode:
      (seq[AssetOutcome](outcome),)
    check AbiEncoder.encode(outcome) == expected

  test "hashes outcomes":
    let outcome = Outcome.example
    let encoded = AbiEncoder.encode(outcome)
    let hashed = keccak256.digest(encoded).data
    check hashOutcome(outcome) == hashed

  test "produces the same encoding as the javascript implementation":
    let outcome = Outcome(@[
      AssetOutcome(
        kind: allocationType,
        assetHolder: !EthAddress.init(
          "1E90B49563da16D2537CA1Ddd9b1285279103D93"
        ),
        allocation: Allocation(@[
          (
            destination: !Destination.parse(
              "f1918e8562236eb17adc8502332f4c9c82bc14e19bfc0aa10ab674ff75b3d2f3"
            ),
            amount: 0x05.u256
          )
        ])
      ),
      AssetOutcome(
        kind: guaranteeType,
        assetHolder: !EthAddress.init(
          "1E90B49563da16D2537CA1Ddd9b1285279103D93"
        ),
        guarantee: Guarantee(
          targetChannelId: !Destination.parse(
            "cac1bb71f0a97c8ac94ca9546b43178a9ad254c7b757ac07433aa6df35cd8089"
          ),
          destinations: @[
            !Destination.parse(
              "f1918e8562236eb17adc8502332f4c9c82bc14e19bfc0aa10ab674ff75b3d2f3"
            )
          ]
        )
      )
    ])
    let expected = fromHex(
      "53993a1bc1de832c2e04bd59491a18d43b6546ec5c611f13dc5dc56d678d228d"
    )
    check hashOutcome(outcome) == expected
