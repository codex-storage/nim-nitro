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

proc `$`*(key: PrivateKey): string =
  key.toHex()

proc parse*(_: type PrivateKey, s: string): ?PrivateKey =
  SkSecretKey.fromHex(s).toOption()
