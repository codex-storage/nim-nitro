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

proc hashMessage(message: openArray[byte]): array[32, byte] =
  # https://eips.ethereum.org/EIPS/eip-191
  var data: seq[byte]
  data.add("\x19Ethereum Signed Message:\n".toBytes)
  data.add(($message.len).toBytes)
  data.add(message)
  keccak256.digest(data).data

proc sign(key: PrivateKey, hash: array[32, byte]): Signature =
  key.signRecoverable(SkMessage(hash))

proc sign*(key: PrivateKey, state: State): Signature =
  let hash = hashMessage(hashState(state))
  key.sign(hash)

proc recover(signature: Signature, hash: array[32, byte]): ?PublicKey =
  recover(signature, SkMessage(hash)).option

proc recover*(signature: Signature, state: State): ?EthAddress =
  let hash = hashMessage(hashState(state))
  recover(signature, hash)?.toAddress

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
