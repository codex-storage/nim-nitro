import std/tables
import ./basics
import ./keys
import ./protocol
import ./channelupdate
import ./ledger

include questionable/errorban

export basics
export keys
export channelupdate

type
  Wallet* = object
    key: PrivateKey
    channels: Table[ChannelId, ChannelUpdate]
  ChannelId* = Destination

func init*(_: type Wallet, key: PrivateKey): Wallet =
  result.key = key

func address*(wallet: Wallet): EthAddress =
  wallet.key.toPublicKey.toAddress

func `[]`*(wallet: Wallet, channel: ChannelId): ?ChannelUpdate =
  wallet.channels[channel].catch.option

func sign(wallet: Wallet, update: ChannelUpdate): ChannelUpdate =
  var signed = update
  signed.signatures &= @{wallet.address: wallet.key.sign(update.state)}
  signed

func createChannel(wallet: var Wallet, update: ChannelUpdate): ChannelId =
  let signed = wallet.sign(update)
  let id = getChannelId(signed.state.channel)
  wallet.channels[id] = signed
  id

func openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        nonce: UInt48,
                        asset: EthAddress,
                        amount: UInt256): ChannelId =
  let update = startLedger(wallet.address, hub, chainId, nonce, asset, amount)
  wallet.createChannel(update)

func acceptChannel*(wallet: var Wallet, update: ChannelUpdate): ?!ChannelId =
  if not update.participants.contains(wallet.address):
    return ChannelId.failure "wallet owner is not a participant"

  if not verifySignatures(update):
    return ChannelId.failure "incorrect signatures"

  wallet.createChannel(update).success
