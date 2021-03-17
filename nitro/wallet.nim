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
    channels*: seq[Channel]
  Channel* = object
    latest*: ChannelUpdate

func init*(_: type Wallet, key: PrivateKey): Wallet =
  result.key = key

func address*(wallet: Wallet): EthAddress =
  wallet.key.toPublicKey.toAddress

func sign(wallet: Wallet, update: ChannelUpdate): ChannelUpdate =
  var signed = update
  signed.signatures &= @{wallet.address: wallet.key.sign(update.state)}
  signed

func createChannel(wallet: var Wallet, update: ChannelUpdate): Channel =
  let signed = wallet.sign(update)
  let channel = Channel(latest: signed)
  wallet.channels.add(channel)
  channel

func openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        nonce: UInt48,
                        asset: EthAddress,
                        amount: UInt256): Channel =
  let update = startLedger(wallet.address, hub, chainId, nonce, asset, amount)
  wallet.createChannel(update)

func acceptChannel*(wallet: var Wallet, update: ChannelUpdate): ?!Channel =
  if not update.participants.contains(wallet.address):
    return Channel.failure "wallet owner is not a participant"

  if not verifySignatures(update):
    return Channel.failure "incorrect signatures"

  wallet.createChannel(update).success
