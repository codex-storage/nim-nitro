import std/tables
import ../basics
import ../keys
import ../protocol
import ./signedstate
import ./ledger
import ./balances
import ./nonces
import ./deref

push: {.upraises:[].}

export basics
export keys
export signedstate
export balances

type
  Wallet* = object
    key: EthPrivateKey
    channels: Table[ChannelId, SignedState]
    nonces: Nonces
  WalletRef* = ref Wallet
  ChannelId* = Destination
  Payment* = tuple
    destination: Destination
    amount: UInt256

func init*(_: type Wallet, key: EthPrivateKey): Wallet =
  Wallet(key: key)

func new*(_: type WalletRef, key: EthPrivateKey): WalletRef =
  WalletRef(key: key)

func publicKey*(wallet: Wallet): EthPublicKey {.deref.} =
  wallet.key.toPublicKey

func address*(wallet: Wallet): EthAddress {.deref.} =
  wallet.publicKey.toAddress

func destination*(wallet: Wallet): Destination {.deref.}=
  wallet.address.toDestination

func sign(wallet: Wallet, state: SignedState): SignedState =
  var signed = state
  signed.signatures &= wallet.key.sign(state.state)
  signed

func incNonce(wallet: var Wallet, state: SignedState) =
  let channel = state.state.channel
  wallet.nonces.incNonce(channel.nonce, channel.chainId, channel.participants)

func createChannel(wallet: var Wallet, state: SignedState): ?!ChannelId =
  let id = getChannelId(state.state.channel)
  if wallet.channels.contains(id):
    return failure "channel with id " & $id & " already exists"
  wallet.channels[id] = wallet.sign(state)
  wallet.incNonce(state)
  success id

func updateChannel(wallet: var Wallet, state: SignedState) =
  let signed = wallet.sign(state)
  let id = getChannelId(signed.state.channel)
  wallet.channels[id] = signed

func openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        nonce: UInt48,
                        asset: EthAddress,
                        amount: UInt256): ?!ChannelId {.deref.} =
  let state = startLedger(wallet.address, hub, chainId, nonce, asset, amount)
  wallet.createChannel(state)

func openLedgerChannel*(wallet: var Wallet,
                        hub: EthAddress,
                        chainId: UInt256,
                        asset: EthAddress,
                        amount: UInt256): ?!ChannelId {.deref.} =
  let nonce = wallet.nonces.getNonce(chainId, wallet.address, hub)
  openLedgerChannel(wallet, hub, chainId, nonce, asset, amount)

func acceptChannel*(wallet: var Wallet,
                    signed: SignedState): ?!ChannelId {.deref.} =
  if not signed.hasParticipant(wallet.address):
    return failure "wallet owner is not a participant"

  if not verifySignatures(signed):
    return failure "incorrect signatures"

  wallet.createChannel(signed)

func latestSignedState*(wallet: Wallet,
                        channel: ChannelId): ?SignedState {.deref.} =
  wallet.channels.?[channel]

func state*(wallet: Wallet,
            channel: ChannelId): ?State {.deref.} =
  wallet.latestSignedState(channel).?state

func signatures*(wallet: Wallet,
                 channel: ChannelId): ?seq[Signature] {.deref.} =
  wallet.latestSignedState(channel).?signatures

func signature*(wallet: Wallet,
                channel: ChannelId,
                address: EthAddress): ?Signature {.deref.} =
  if signed =? wallet.latestSignedState(channel):
    for signature in signed.signatures:
      if signer =? signature.recover(signed.state):
        if signer == address:
          return signature.some
  Signature.none

func balance(state: State,
             asset: EthAddress,
             destination: Destination): UInt256 =
  without balance =? state.outcome.balances(asset).?[destination]:
    return 0.u256
  balance

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress,
              destination: Destination): UInt256 {.deref.} =
  without state =? wallet.state(channel):
    return 0.u256
  state.balance(asset, destination)

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress,
              address: EthAddress): UInt256 {.deref.} =
  wallet.balance(channel, asset, address.toDestination)

func balance*(wallet: Wallet,
              channel: ChannelId,
              asset: EthAddress): UInt256 {.deref.} =
  wallet.balance(channel, asset, wallet.address)

func total(state: State, asset: EthAddress): UInt256 =
  var total: UInt256
  if balances =? state.outcome.balances(asset):
    for amount in balances.values:
      total += amount # TODO: overflow?
  total

func total(wallet: Wallet, channel: ChannelId, asset: EthAddress): UInt256 =
  without state =? wallet.state(channel):
    return 0.u256
  state.total(asset)

func pay*(wallet: var Wallet,
          channel: ChannelId,
          asset: EthAddress,
          receiver: Destination,
          amount: UInt256): ?!SignedState {.deref.} =
  without var state =? wallet.state(channel):
    return failure "channel not found"

  without var balances =? state.outcome.balances(asset):
    return failure "asset not found"

  ?balances.move(wallet.destination, receiver, amount)
  state.outcome.update(asset, balances)
  wallet.updateChannel(SignedState(state: state))
  success !wallet.latestSignedState(channel)

func pay*(wallet: var Wallet,
          channel: ChannelId,
          asset: EthAddress,
          receiver: EthAddress,
          amount: UInt256): ?!SignedState {.deref.} =
  wallet.pay(channel, asset, receiver.toDestination, amount)

func acceptPayment*(wallet: var Wallet,
                    channel: ChannelId,
                    asset: EthAddress,
                    sender: EthAddress,
                    payment: SignedState): ?!void {.deref.} =
  if not wallet.channels.contains(channel):
    return failure "unknown channel"

  if not (getChannelId(payment.state.channel) == channel):
    return failure "payment does not match channel"

  let currentBalance = wallet.balance(channel, asset)
  let futureBalance = payment.state.balance(asset, wallet.destination)
  if futureBalance <= currentBalance:
    return failure "payment should not decrease balance"

  let currentTotal = wallet.total(channel, asset)
  let futureTotal = payment.state.total(asset)
  if futureTotal != currentTotal:
    return failure "total supply of asset should not change"

  if not payment.isSignedBy(sender):
    return failure "missing signature on payment"

  without updatedBalances =? payment.state.outcome.balances(asset):
    return failure "payment misses balances for asset"

  var expectedState: State = !wallet.state(channel)
  expectedState.outcome.update(asset, updatedBalances)
  if payment.state != expectedState:
    return failure "payment has unexpected changes in state"

  wallet.channels[channel] = payment
  success()
