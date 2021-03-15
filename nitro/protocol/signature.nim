import pkg/secp256k1
import pkg/nimcrypto
import pkg/stew/byteutils
import ../basics
import ../keys
import ./state

include questionable/errorban

export basics
export keys

type Signature* = SkRecoverableSignature

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

proc parse*(_: type Signature, s: string): ?Signature =
  let signature = catch:
    var bytes = array[65, byte].fromHex(s)
    bytes[64] = bytes[64] - 27
    SkRecoverableSignature.fromRaw(bytes).get()
  signature.option
