import ./basics
import ./keys
import ./protocol

include questionable/errorban

export basics
export keys

type
  Wallet* = object
    key: PrivateKey
    channels*: seq[Channel]
  Channel* = object
    latest*, upcoming*: ?ChannelUpdate
  ChannelUpdate* = object
    state*: State
    signatures*: seq[(EthAddress, Signature)]

proc init*(_: type Wallet, key: PrivateKey): Wallet =
  result.key = key

proc address*(wallet: Wallet): EthAddress =
  wallet.key.toPublicKey.toAddress

proc openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        nonce: UInt48,
                        asset: EthAddress,
                        amount: UInt256): Channel =
  let state = State(
    channel: ChannelDefinition(
      chainId: chainId,
      participants: @[wallet.address, hub],
      nonce: nonce
    ),
    outcome: Outcome.init(asset, {wallet.address.toDestination: amount})
  )
  let channel = Channel(
    upcoming: ChannelUpdate(
      state: state,
      signatures: @{wallet.address: wallet.key.sign(state)}
    ).some
  )
  wallet.channels.add(channel)
  channel
