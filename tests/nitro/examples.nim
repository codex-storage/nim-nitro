import std/random
import std/sequtils
import pkg/nitro

randomize()

proc example*(_: type bool): bool =
  rand(0'u8..1'u8) == 1

proc example*[T: SomeInteger](_: type T): T =
  rand(T)

proc example*[I: static int, T](_: type array[I, T]): array[I, T] =
  for i in 0..<I:
    result[i] = T.example

proc example*[T](_: type seq[T], len = 0..5): seq[T] =
  let chosenlen = rand(len)
  newSeqWith(chosenlen, T.example)

proc example*(_: type UInt256): UInt256 =
  UInt256.fromBytes(array[32, byte].example)

proc example*(_: type UInt128): UInt128 =
  UInt128.fromBytes(array[16, byte].example)

proc example*(_: type EthAddress): EthAddress =
  EthAddress(array[20, byte].example)

proc example*(_: type Channel): Channel =
  Channel(
    nonce: UInt48.example,
    participants: seq[EthAddress].example(2..5),
    chainId: UInt256.example
  )

proc example*(_: type AllocationItem): AllocationItem =
  AllocationItem(
    destination: array[32, byte].example,
    amount: UInt256.example
  )

proc example*(_: type Guarantee): Guarantee =
  Guarantee(
    targetChannelId: array[32, byte].example,
    destinations: seq[array[32, byte]].example
  )

proc example*(_: type Allocation): Allocation =
  Allocation(seq[AllocationItem].example)

proc example*(_: type AssetOutcome): AssetOutcome =
  let kind = rand(AssetOutcomeType.low..AssetOutcomeType.high)
  case kind:
  of allocationType:
    AssetOutcome(
      kind: allocationType,
      assetHolder: EthAddress.example,
      allocation: Allocation.example
    )
  of guaranteeType:
    AssetOutcome(
      kind: guaranteeType,
      assetHolder: EthAddress.example,
      guarantee: Guarantee.example
    )

proc example*(_: type Outcome): Outcome =
  Outcome(seq[AssetOutcome].example)

proc example*(_: type State): State =
  State(
    turnNum: UInt48.example,
    isFinal: bool.example,
    channel: Channel.example,
    challengeDuration: UInt48.example,
    outcome: Outcome.example,
    appDefinition: EthAddress.example,
    appData: seq[byte].example
  )
