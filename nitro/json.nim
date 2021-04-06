import std/json
import std/typetraits
import pkg/stew/byteutils
import ./basics
import ./protocol
import ./wallet/signedstate

export signedstate

push: {.upraises:[].}

func `%`(value: Outcome | Allocation): JsonNode =
  type Base = distinctBase(typeof value)
  %(Base(value))

func `%`(value: seq[byte]): JsonNode =
  %value.toHex

func `%`(value: EthAddress | Destination): JsonNode =
  %($value)

func `%`(value: UInt256): JsonNode =
  %(value.toHex)

func `%`(value: Signature): JsonNode =
  %($value)

func `%`(value: AllocationItem): JsonNode =
  %*{
    "destination": value.destination,
    "amount": value.amount
  }

func toJson*(payment: SignedState): string =
  $(%*payment)

{.pop.}

push: {.upraises: [ValueError].}

func expectKind(node: JsonNode, kind: JsonNodeKind) =
  if node.kind != kind:
    let message = "expected " & $kind & ", got: " & $node.kind
    raise newException(JsonKindError, message)

func initFromJson*(bytes: var seq[byte], node: JsonNode, _: var string) =
  node.expectKind(JString)
  let parsed = seq[byte].fromHex(node.getStr)
  if parsed.isOk:
    bytes = parsed.get
  else:
    raise newException(ValueError, "invalid hex string")

func initFromJson*(address: var EthAddress, node: JsonNode, _: var string) =
  node.expectKind(JString)
  let parsed = EthAddress.parse(node.getStr)
  if parsed.isSome:
    address = parsed.get
  else:
    raise newException(ValueError, "invalid ethereum address")

func initFromJson*(dest: var Destination, node: JsonNode, _: var string) =
  node.expectKind(JString)
  let parsed = Destination.parse(node.getStr)
  if parsed.isSome:
    dest = parsed.get
  else:
    raise newException(ValueError, "invalid nitro destination")

func initFromJson*(number: var UInt256, node: JsonNode, _: var string) =
  node.expectKind(JString)
  number = UInt256.fromHex(node.getStr)

func initFromJson*(signature: var Signature, node: JsonNode, _: var string) =
  node.expectKind(JString)
  let parsed = Signature.parse(node.getStr)
  if parsed.isSome:
    signature = parsed.get
  else:
    raise newException(ValueError, "invalid signature")

{.pop.}

push: {.upraises: [].}

proc fromJson*(_: type SignedState, json: string): ?SignedState =
  try:
    {.warning[UnsafeSetLen]: off.}
    return parseJson(json).to(SignedState).some
    {.warning[UnsafeSetLen]: on.}
  except ValueError:
    return SignedState.none
  except Exception as error:
    raise (ref Defect)(msg: error.msg, parent: error)

{.pop.}
