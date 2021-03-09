import pkg/nimcrypto
import ../basics
import ./abi

include questionable/errorban

export basics

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
  Allocation* = distinct seq[AllocationItem]
  AllocationItem* = tuple
    destination: Destination
    amount: UInt256
  Guarantee* = object
    targetChannelId*: Destination
    destinations*: seq[Destination]

proc init*(_: type Outcome,
           asset: EthAddress,
           allocation: openArray[AllocationItem]): Outcome =
  let assetOutcome = AssetOutcome(
    kind: allocationType,
    assetHolder: asset,
    allocation: Allocation(@allocation)
  )
  Outcome(@[assetOutcome])

proc `==`*(a, b: Allocation): bool {.borrow.}

proc `==`*(a, b: AssetOutcome): bool =
  if a.kind != b.kind:
    return false
  if a.assetHolder != b.assetHolder:
    return false
  case a.kind:
    of allocationType:
      a.allocation == b.allocation
    of guaranteeType:
      a.guarantee == b.guarantee

proc `==`*(a, b: Outcome): bool {.borrow.}

proc encode*(encoder: var AbiEncoder, guarantee: Guarantee) =
  encoder.startTuple()
  encoder.startTuple()
  encoder.write(guarantee.targetChannelId)
  encoder.write(guarantee.destinations)
  encoder.finishTuple()
  encoder.finishTuple()

proc encode*(encoder: var AbiEncoder, item: AllocationItem) =
  encoder.startTuple()
  encoder.write(item.destination)
  encoder.write(item.amount)
  encoder.finishTuple()

proc encode*(encoder: var AbiEncoder, allocation: Allocation) =
  encoder.startTuple()
  encoder.write(seq[AllocationItem](allocation))
  encoder.finishTuple()

proc encode*(encoder: var AbiEncoder, assetOutcome: AssetOutcome) =
  var content= AbiEncoder.init()
  content.startTuple()
  content.startTuple()
  content.write(assetOutcome.kind)
  case assetOutcome.kind:
  of allocationType:
    content.write(AbiEncoder.encode(assetOutcome.allocation))
  of guaranteeType:
    content.write(AbiEncoder.encode(assetOutcome.guarantee))
  content.finishTuple()
  content.finishTuple()

  encoder.startTuple()
  encoder.write(assetOutcome.assetHolder)
  encoder.write(content.finish())
  encoder.finishTuple()

proc encode*(encoder: var AbiEncoder, outcome: Outcome) =
  encoder.startTuple()
  encoder.write(seq[AssetOutcome](outcome))
  encoder.finishTuple()

proc hashOutcome*(outcome: Outcome): array[32, byte] =
  keccak256.digest(AbiEncoder.encode(outcome)).data
