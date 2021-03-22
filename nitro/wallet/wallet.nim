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
  signed.signatures &= wallet.key.sign(state.state)
  signed

func createChannel(wallet: var Wallet, state: SignedState): ?!ChannelId =
  let id = getChannelId(state.state.channel)
  if wallet.channels.contains(id):
    return ChannelId.failure("channel with id " & $id & " already exists")
  wallet.channels[id] = wallet.sign(state)
  ok id

func updateChannel(wallet: var Wallet, state: SignedState) =
  let signed = wallet.sign(state)
  let id = getChannelId(signed.state.channel)
  wallet.channels[id] = signed

func openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        nonce: UInt48,
                        asset: EthAddress,
                        amount: UInt256): ?!ChannelId =
  let state = startLedger(wallet.address, hub, chainId, nonce, asset, amount)
  wallet.createChannel(state)

func acceptChannel*(wallet: var Wallet, signed: SignedState): ?!ChannelId =
  if not signed.hasParticipant(wallet.address):
    return ChannelId.failure "wallet owner is not a participant"

  if not verifySignatures(signed):
    return ChannelId.failure "incorrect signatures"

  wallet.createChannel(signed)

func latestSignedState*(wallet: Wallet, channel: ChannelId): ?SignedState =
  wallet.channels?[channel]

func state*(wallet: Wallet, channel: ChannelId): ?State =
  wallet.latestSignedState(channel)?.state

func signatures*(wallet: Wallet, channel: ChannelId): ?seq[Signature] =
  wallet.latestSignedState(channel)?.signatures

func signature*(wallet: Wallet,
                channel: ChannelId,
                address: EthAddress): ?Signature =
  if signed =? wallet.latestSignedState(channel):
    for signature in signed.signatures:
      if signer =? signature.recover(signed.state):
        if signer == address:
          return signature.some
  Signature.none

func balance(state: State,
             asset: EthAddress,
             destination: Destination): UInt256 =
  if balances =? state.outcome.balances(asset):
    if balance =? (balances?[destination]):
      balance
    else:
      0.u256
  else:
    0.u256

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress,
              destination: Destination): UInt256 =
  if state =? wallet.state(channel):
    state.balance(asset, destination)
  else:
    0.u256

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress,
              address: EthAddress): UInt256 =
  wallet.balance(channel, asset, address.toDestination)

func balance*(wallet: Wallet, channel: ChannelId, asset: EthAddress): UInt256 =
  wallet.balance(channel, asset, wallet.address)

func total(state: State, asset: EthAddress): UInt256 =
  var total: UInt256
  if balances =? state.outcome.balances(asset):
    for amount in balances.values:
      total += amount # TODO: overflow?
  total

func total(wallet: Wallet, channel: ChannelId, asset: EthAddress): UInt256 =
  if state =? wallet.state(channel):
    state.total(asset)
  else:
    0.u256

func pay*(wallet: var Wallet,
          channel: ChannelId,
          asset: EthAddress,
          receiver: Destination,
          amount: UInt256): ?!SignedState =
  if var state =? wallet.state(channel):
    if var balances =? state.outcome.balances(asset):
      ?balances.move(wallet.destination, receiver, amount)
      state.outcome.update(asset, balances)
      wallet.updateChannel(SignedState(state: state))
      ok(wallet.channels?[channel].get)
    else:
      SignedState.failure "asset not found"
  else:
    SignedState.failure "channel not found"

func pay*(wallet: var Wallet,
          channel: ChannelId,
          asset: EthAddress,
          receiver: EthAddress,
          amount: UInt256): ?!SignedState =
  wallet.pay(channel, asset, receiver.toDestination, amount)

func acceptPayment*(wallet: var Wallet,
                    channel: ChannelId,
                    asset: EthAddress,
                    sender: EthAddress,
                    payment: SignedState): ?!void =
  if not wallet.channels.contains(channel):
    return void.failure "unknown channel"

  if not (getChannelId(payment.state.channel) == channel):
    return void.failure "payment does not match channel"

  let currentBalance = wallet.balance(channel, asset)
  let futureBalance = payment.state.balance(asset, wallet.destination)
  if futureBalance <= currentBalance:
    return void.failure "payment should not decrease balance"

  let currentTotal = wallet.total(channel, asset)
  let futureTotal = payment.state.total(asset)
  if futureTotal != currentTotal:
    return void.failure "total supply of asset should not change"

  if not payment.isSignedBy(sender):
    return void.failure "missing signature on payment"

  if updatedBalances =? payment.state.outcome.balances(asset):
    var expectedState: State = wallet.channels?[channel]?.state.get
    expectedState.outcome.update(asset, updatedBalances)
    if payment.state != expectedState:
      return void.failure "payment has unexpected changes in state"
  else:
    return void.failure "payment misses balances for asset"

  wallet.channels[channel] = payment
  ok()
