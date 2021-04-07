import pkg/secp256k1
import pkg/nimcrypto
import ./basics

export basics
export toPublicKey

push: {.upraises:[].}

type
  EthPrivateKey* = SkSecretKey
  EthPublicKey* = SkPublicKey

proc rng(data: var openArray[byte]): bool =
  randomBytes(data) == data.len

proc random*(_: type EthPrivateKey): EthPrivateKey =
  EthPrivateKey.random(rng).get()

func `$`*(key: EthPrivateKey): string =
  key.toHex()

func parse*(_: type EthPrivateKey, s: string): ?EthPrivateKey =
  SkSecretKey.fromHex(s).option

func toAddress*(key: EthPublicKey): EthAddress =
  let hash = keccak256.digest(key.toRaw())
  var bytes: array[20, byte]
  for i in 0..<20:
    bytes[i] = hash.data[12 + i]
  EthAddress(bytes)
