import pkg/secp256k1
import pkg/nimcrypto
import pkg/stew/byteutils
import ../basics
import ../keys
import ./state

push: {.upraises:[].}

export basics
export keys

type Signature* = SkRecoverableSignature

func hashMessage(message: openArray[byte]): array[32, byte] =
  # https://eips.ethereum.org/EIPS/eip-191
  var data: seq[byte]
  data.add("\x19Ethereum Signed Message:\n".toBytes)
  data.add(($message.len).toBytes)
  data.add(message)
  keccak256.digest(data).data

func sign(key: EthPrivateKey, hash: array[32, byte]): Signature =
  key.signRecoverable(SkMessage(hash))

func sign*(key: EthPrivateKey, state: State): Signature =
  let hash = hashMessage(hashState(state))
  key.sign(hash)

func recover(signature: Signature, hash: array[32, byte]): ?EthPublicKey =
  recover(signature, SkMessage(hash)).option

func recover*(signature: Signature, state: State): ?EthAddress =
  let hash = hashMessage(hashState(state))
  recover(signature, hash)?.toAddress

func verify*(signature: Signature, state: State, signer: EthAddress): bool =
  recover(signature, state) == signer.some

func `$`*(signature: Signature): string =
  var bytes = signature.toRaw()
  bytes[64] += 27
  bytes.toHex()

func parse*(_: type Signature, s: string): ?Signature =
  let signature = catch:
    var bytes = array[65, byte].fromHex(s)
    bytes[64] = bytes[64] - 27
    SkRecoverableSignature.fromRaw(bytes).get()
  signature.option
