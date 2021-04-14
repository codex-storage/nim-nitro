import std/tables
import std/sets
import std/hashes
import ../basics

push: {.upraises: [].}

type
  Nonces* = object
    next: Table[NonceKey, UInt48]
  NonceKey = object
    chainId: UInt256
    participants: HashSet[EthAddress]

func hash(key: NonceKey): Hash =
  var h: Hash
  h = h !& key.chainId.hash
  h = h !& key.participants.hash
  !$h

func key(chainId: UInt256, participants: openArray[EthAddress]): NonceKey =
  NonceKey(chainId: chainId, participants: participants.toHashSet)

func getNonce*(nonces: var Nonces,
               chainId: UInt256,
               participants: varargs[EthAddress]): UInt48 =
  nonces.next.?[key(chainId, participants)] |? 0

func incNonce*(nonces: var Nonces,
               oldNonce: UInt48,
               chainId: UInt256,
               participants: varargs[EthAddress]) =
  let next = max(oldNonce, nonces.getNonce(chainId, participants)) + 1
  nonces.next[key(chainId, participants)] = next
