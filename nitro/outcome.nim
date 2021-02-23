import pkg/nimcrypto
import ./abi
import ./types

export types
export abi

type
  Outcome* = distinct seq[AssetOutcome]
  AssetOutcomeType* = enum
    allocationType = 0
    guaranteeType = 1
  AssetOutcome* = object
    assetHolder*: EthAddress
    case kind*: AssetOutcomeType
    of allocationType:
      allocation*: Allocation
    of guaranteeType:
      guarantee*: Guarantee
  Allocation* = seq[AllocationItem]
  AllocationItem* = object
    destination*: array[32, byte]
    amount*: UInt256
  Guarantee* = object
    targetChannelId*: array[32, byte]
    destinations*: seq[array[32, byte]]

proc isStatic*(_: type Abi, t: type AssetOutcome): bool = false
proc isStatic*(_: type Abi, t: type AllocationItem): bool = true
proc isStatic*(_: type Abi, t: type Guarantee): bool = false

proc write*(writer: var AbiWriter, guarantee: Guarantee) =
  writer.startTuple()
  writer.write(guarantee.targetChannelId)
  writer.write(guarantee.destinations)
  writer.finishTuple()

proc write*(writer: var AbiWriter, item: AllocationItem) =
  writer.startTuple()
  writer.write(item.destination)
  writer.write(item.amount)
  writer.finishTuple()

proc write*(writer: var AbiWriter, assetOutcome: AssetOutcome) =
  var content: AbiWriter
  content.startTuple()
  content.write(assetOutcome.kind)
  case assetOutcome.kind:
  of allocationType:
    content.write(Abi.encode(assetOutcome.allocation))
  of guaranteeType:
    content.write(Abi.encode(assetOutcome.guarantee))
  content.finishTuple()
  writer.startTuple()
  writer.write(assetOutcome.assetHolder)
  writer.write(content.finish())
  writer.finishTuple()

proc write*(writer: var AbiWriter, outcome: Outcome) =
  writer.startTuple()
  writer.write(seq[AssetOutcome](outcome))
  writer.finishTuple()

proc hashOutcome*(outcome: Outcome): array[32, byte] =
  keccak256.digest(Abi.encode(outcome)).data
