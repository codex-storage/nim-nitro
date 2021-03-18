import std/tables
import ../basics
import ../keys
import ../protocol
import ./signedstate
import ./ledger
import ./balances

include questionable/errorban

export basics
export keys
export signedstate
export balances

type
  Wallet* = object
    key: PrivateKey
    channels: Table[ChannelId, SignedState]
  ChannelId* = Destination
  Payment* = tuple
    destination: Destination
    amount: UInt256

func init*(_: type Wallet, key: PrivateKey): Wallet =
  result.key = key

func address*(wallet: Wallet): EthAddress =
  wallet.key.toPublicKey.toAddress

func destination*(wallet: Wallet): Destination =
  wallet.address.toDestination

func sign(wallet: Wallet, state: SignedState): SignedState =
  var signed = state
  signed.signatures &= @{wallet.address: wallet.key.sign(state.state)}
  signed

func createChannel(wallet: var Wallet, state: SignedState): ChannelId =
  let signed = wallet.sign(state)
  let id = getChannelId(signed.state.channel)
  wallet.channels[id] = signed
  id

func updateChannel(wallet: var Wallet, state: SignedState) =
  let signed = wallet.sign(state)
  let id = getChannelId(signed.state.channel)
  wallet.channels[id] = signed

func openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        nonce: UInt48,
                        asset: EthAddress,
                        amount: UInt256): ChannelId =
  let state = startLedger(wallet.address, hub, chainId, nonce, asset, amount)
  wallet.createChannel(state)

func acceptChannel*(wallet: var Wallet, signed: SignedState): ?!ChannelId =
  if not signed.hasParticipant(wallet.address):
    return ChannelId.failure "wallet owner is not a participant"

  if not verifySignatures(signed):
    return ChannelId.failure "incorrect signatures"

  wallet.createChannel(signed).success

func state*(wallet: Wallet, channel: ChannelId): ?State =
  try:
    wallet.channels[channel].state.some
  except KeyError:
    State.none

func signatures*(wallet: Wallet, channel: ChannelId): ?Signatures =
  try:
    wallet.channels[channel].signatures.some
  except KeyError:
    Signatures.none

func signature*(wallet: Wallet,
                channel: ChannelId,
                address: EthAddress): ?Signature =
  if signatures =? wallet.signatures(channel):
    for (signer, signature) in signatures:
      if signer == address:
        return signature.some
  Signature.none

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress,
              destination: Destination): UInt256 =
  if state =? wallet.state(channel):
    if balances =? state.outcome.balances(asset):
      try:
        return balances[destination]
      except KeyError:
        return 0.u256
  0.u256

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress,
              address: EthAddress): UInt256 =
  wallet.balance(channel, asset, address.toDestination)

func pay*(wallet: var Wallet,
          channel: ChannelId,
          asset: EthAddress,
          receiver: Destination,
          amount: UInt256): ?!void =
  if var state =? wallet.state(channel):
    if var balances =? state.outcome.balances(asset):
      ?balances.move(wallet.destination, receiver, amount)
      try:
        state.outcome.update(asset, balances)
        wallet.updateChannel(SignedState(state: state))
        ok()
      except KeyError as error:
        void.failure error
    else:
      void.failure "asset not found"
  else:
    void.failure "channel not found"

func pay*(wallet: var Wallet,
          channel: ChannelId,
          asset: EthAddress,
          receiver: EthAddress,
          amount: UInt256): ?!void =
  wallet.pay(channel, asset, receiver.toDestination, amount)
