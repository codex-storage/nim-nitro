import ./basics
import ./keys
import ./protocol

include questionable/errorban

export basics
export keys

type
  Wallet* = object
    key: PrivateKey
    channels: seq[Channel]
  Channel* = object
    latest*, upcoming*: ?StateUpdate
  StateUpdate* = object
    state*: State
    signatures*: seq[(EthAddress, Signature)]

proc init*(_: type Wallet, key: PrivateKey): Wallet =
  result.key = key

proc address*(wallet: Wallet): EthAddress =
  wallet.key.toPublicKey.toAddress

proc openLedger*(wallet: Wallet, asset: EthAddress, amount: UInt256): Channel =
  let me = wallet.address.toDestination
  let outcome = Outcome.init(asset, {me: amount})
  let state = State(outcome: outcome)
  let signature = wallet.key.sign(state)
  let update = StateUpdate(state: state, signatures: @{wallet.address: signature})
  Channel(upcoming: update.some)
