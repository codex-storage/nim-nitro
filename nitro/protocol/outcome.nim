import pkg/nimcrypto
import ../basics
import ./abi

push: {.upraises:[].}

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

func init*(_: type Outcome,
           asset: EthAddress,
           allocation: openArray[AllocationItem]): Outcome =
  let assetOutcome = AssetOutcome(
    kind: allocationType,
    assetHolder: asset,
    allocation: Allocation(@allocation)
  )
  Outcome(@[assetOutcome])

proc `==`*(a, b: Allocation): bool {.borrow.}

func `==`*(a, b: AssetOutcome): bool =
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

func encode*(encoder: var AbiEncoder, guarantee: Guarantee) =
  encoder.write:
    ( (guarantee.targetChannelId, guarantee.destinations), )

func encode*(encoder: var AbiEncoder, allocation: Allocation) =
  encoder.write: (seq[AllocationItem](allocation),)

func encode*(encoder: var AbiEncoder, assetOutcome: AssetOutcome) =
  var content: seq[byte]
  case assetOutcome.kind:
  of allocationType:
    content = AbiEncoder.encode:
      ( (assetOutcome.kind, ABiEncoder.encode(assetOutcome.allocation)), )
  of guaranteeType:
    content = AbiEncoder.encode:
      ( (assetOutcome.kind, AbiEncoder.encode(assetOutcome.guarantee)), )
  encoder.write( (assetOutcome.assetHolder, content) )

func encode*(encoder: var AbiEncoder, outcome: Outcome) =
  encoder.write: (seq[AssetOutcome](outcome),)

func hashOutcome*(outcome: Outcome): array[32, byte] =
  keccak256.digest(AbiEncoder.encode(outcome)).data
