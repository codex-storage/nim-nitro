import std/options
import pkg/nimcrypto
import pkg/secp256k1
import pkg/stew/byteutils
import ../helpers
import ./state

include ../noerrors

export options
export toPublicKey

type
  PrivateKey* = SkSecretKey
  PublicKey* = SkPublicKey
  Signature* = SkRecoverableSignature

proc rng(data: var openArray[byte]): bool =
  randomBytes(data) == data.len

proc random*(_: type PrivateKey): PrivateKey =
  PrivateKey.random(rng).get()

proc `$`*(key: PrivateKey): string =
  key.toHex()

proc parse*(_: type PrivateKey, s: string): Option[PrivateKey] =
  SkSecretKey.fromHex(s).toOption()

proc sign(key: PrivateKey, data: openArray[byte]): Signature =
  let hash = keccak256.digest(data).data
  key.signRecoverable(SkMessage(hash))

proc signMessage(key: PrivateKey, message: openArray[byte]): Signature =
  # https://eips.ethereum.org/EIPS/eip-191
  var data: seq[byte]
  data.add("\x19Ethereum Signed Message:\n".toBytes)
  data.add(($message.len).toBytes)
  data.add(message)
  key.sign(data)

proc sign*(key: PrivateKey, state: State): Signature =
  key.signMessage(hashState(state))

proc `$`*(signature: Signature): string =
  var bytes = signature.toRaw()
  bytes[64] += 27
  bytes.toHex()

proc parse*(_: type Signature, s: string): Option[Signature] =
  try:
    var bytes = array[65, byte].fromHex(s)
    bytes[64] = bytes[64] - 27
    SkRecoverableSignature.fromRaw(bytes).toOption()
  except ValueError:
    Signature.none
