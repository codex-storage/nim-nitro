import pkg/secp256k1
import pkg/nimcrypto
import ./basics

export basics
export toPublicKey

include questionable/errorban

type
  PrivateKey* = SkSecretKey
  PublicKey* = SkPublicKey

proc rng(data: var openArray[byte]): bool =
  randomBytes(data) == data.len

proc random*(_: type PrivateKey): PrivateKey =
  PrivateKey.random(rng).get()

func `$`*(key: PrivateKey): string =
  key.toHex()

func parse*(_: type PrivateKey, s: string): ?PrivateKey =
  SkSecretKey.fromHex(s).option

func toAddress*(key: PublicKey): EthAddress =
  let hash = keccak256.digest(key.toRaw())
  var bytes: array[20, byte]
  for i in 0..<20:
    bytes[i] = hash.data[12 + i]
  EthAddress(bytes)
