import ./basics

suite "wallet":

  test "wallet is created from private key":
    let key = PrivateKey.random()
    let wallet = Wallet.init(key)
    check wallet.address == key.toPublicKey.toAddress

suite "wallet: opening ledger channel":

  let key = PrivateKey.random()
  let asset = EthAddress.example
  let amount = 42.u256
  let hub = EthAddress.example
  let chainId = UInt256.example
  let nonce = UInt48.example

  var wallet: Wallet
  var channel: ChannelId

  setup:
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, amount).get

  test "sets correct channel definition":
    let definition = wallet.state(channel).get.channel
    check definition.chainId == chainId
    check definition.nonce == nonce
    check definition.participants == @[wallet.address, hub]

  test "provides correct outcome":
    let outcome = wallet.state(channel).get.outcome
    check outcome == Outcome.init(asset, {wallet.destination: amount})

  test "signs the state":
    let state = wallet.state(channel).get
    let signatures = wallet.signatures(channel).get
    check signatures == @[key.sign(state)]

  test "sets app definition and app data to zero":
    check wallet.state(channel).get.appDefinition == EthAddress.zero
    check wallet.state(channel).get.appData.len == 0

  test "does not allow opening a channel that already exists":
    check wallet.openLedgerChannel(hub, chainId, nonce, asset, amount).isErr

suite "wallet: accepting incoming channel":

  let key = PrivateKey.random()
  var wallet: Wallet
  var signed: SignedState

  setup:
    wallet = Wallet.init(key)
    signed = SignedState(state: State.example)
    signed.state.channel.participants &= @[wallet.address]

  test "returns the new channel id":
    let channel = wallet.acceptChannel(signed).get
    check wallet.state(channel).get == signed.state

  test "signs the channel state":
    let channel = wallet.acceptChannel(signed).get
    let expectedSignatures = @[key.sign(signed.state)]
    check wallet.signatures(channel).get == expectedSignatures

  test "fails when wallet address is not a participant":
    let wrongParticipants = seq[EthAddress].example
    signed.state.channel.participants = wrongParticipants
    check wallet.acceptChannel(signed).isErr

  test "fails when signatures are incorrect":
    signed.signatures = @[key.sign(State.example)]
    check wallet.acceptChannel(signed).isErr

  test "fails when channel with this id already exists":
    check wallet.acceptChannel(signed).isOk
    check wallet.acceptChannel(signed).isErr

suite "wallet: making payments":

  let key = PrivateKey.random()
  let asset = EthAddress.example
  let hub = EthAddress.example
  let chainId = UInt256.example
  let nonce = UInt48.example

  var wallet: Wallet
  var channel: ChannelId

  test "paying updates the channel state":
    wallet = Wallet.init(key)
    let me = wallet.address
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 100.u256).get

    check wallet.pay(channel, asset, hub, 1.u256).isOk
    check wallet.balance(channel, asset, me) == 99.u256
    check wallet.balance(channel, asset, hub) == 1.u256

    check wallet.pay(channel, asset, hub, 2.u256).isOk
    check wallet.balance(channel, asset, me) == 97.u256
    check wallet.balance(channel, asset, hub) == 3.u256

  test "paying updates signatures":
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 100.u256).get
    check wallet.pay(channel, asset, hub, 1.u256).isOk
    let expectedSignature = key.sign(wallet.state(channel).get)
    check wallet.signature(channel, wallet.address) == expectedSignature.some

  test "pay returns the updated signed state":
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 42.u256).get
    let updated = wallet.pay(channel, asset, hub, 1.u256).option
    check updated?.state == wallet.state(channel)
    check updated?.signatures == wallet.signatures(channel)

  test "payment fails when channel not found":
    wallet = Wallet.init(key)
    check wallet.pay(channel, asset, hub, 1.u256).isErr

  test "payment fails when asset not found":
    wallet = Wallet.init(key)
    var state = State.example
    state.channel.participants &= wallet.address
    channel = wallet.acceptChannel(SignedState(state: state)).get
    check wallet.pay(channel, asset, hub, 1.u256).isErr

  test "payment fails when payer has no allocation":
    wallet = Wallet.init(key)
    var state: State
    state.channel = ChannelDefinition(participants: @[wallet.address])
    state.outcome = Outcome.init(asset, @[])
    channel = wallet.acceptChannel(SignedState(state: state)).get
    check wallet.pay(channel, asset, hub, 1.u256).isErr

  test "payment fails when payer has insufficient funds":
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 1.u256).get
    check wallet.pay(channel, asset, hub, 1.u256).isOk
    check wallet.pay(channel, asset, hub, 1.u256).isErr

suite "wallet: accepting payments":

  let payerKey, receiverKey = PrivateKey.random()
  let asset = EthAddress.example
  let chainId = UInt256.example
  let nonce = UInt48.example

  var payer, receiver: Wallet
  var channel: ChannelId

  setup:
    payer = Wallet.init(payerKey)
    receiver = Wallet.init(receiverKey)
    channel = payer.openLedgerChannel(
      receiver.address, chainId, nonce, asset, 100.u256).get
    let update = payer.latestSignedState(channel).get
    discard receiver.acceptChannel(update)

  test "updates channel state":
    let payment = payer.pay(channel, asset, receiver.address, 42.u256).get
    check receiver.acceptPayment(channel, asset, payer.address, payment).isOk
    check receiver.balance(channel, asset, receiver.address) == 42.u256

  test "fails when receiver balance is decreased":
    let payment1 = payer.pay(channel, asset, receiver.address, 10.u256).get
    let payment2 = payer.pay(channel, asset, receiver.address, 10.u256).get
    check receiver.acceptPayment(channel, asset, payer.address, payment1).isOk
    check receiver.acceptPayment(channel, asset, payer.address, payment2).isOk
    check receiver.acceptPayment(channel, asset, payer.address, payment1).isErr
    check receiver.balance(channel, asset, receiver.address) == 20

  test "fails when the total supply of the asset changes":
    var payment = payer.pay(channel, asset, receiver.address, 10.u256).get
    var balances = payment.state.outcome.balances(asset).get
    balances[payer.destination] += 10.u256
    payment.state.outcome.update(asset, balances)
    check receiver.acceptPayment(channel, asset, payer.address, payment).isErr

  test "fails without a signature":
    var payment = payer.pay(channel, asset, receiver.address, 10.u256).get
    payment.signatures = @[]
    check receiver.acceptPayment(channel, asset, payer.address, payment).isErr

  test "fails with an incorrect signature":
    var payment = payer.pay(channel, asset, receiver.address, 10.u256).get
    payment.signatures = @[Signature.example]
    check receiver.acceptPayment(channel, asset, payer.address, payment).isErr

  test "fails when channel is unknown":
    let newChannel = payer.openLedgerChannel(
      receiver.address, chainId, nonce + 1, asset, 100.u256).get
    let payment = payer.pay(newChannel, asset, receiver.address, 10.u256).get
    check receiver.acceptPayment(newChannel, asset, payer.address, payment).isErr

  test "fails when payment does not match channel":
    let newChannel = payer.openLedgerChannel(
      receiver.address, chainId, nonce + 1, asset, 100.u256).get
    let payment = payer.pay(newChannel, asset, receiver.address, 10.u256).get
    check receiver.acceptPayment(channel, asset, payer.address, payment).isErr

  test "fails when state is updated in unrelated areas":
    var payment = payer.pay(channel, asset, receiver.address, 10.u256).get
    payment.state.appDefinition = EthAddress.example
    payment.signatures = @[payerKey.sign(payment.state)]
    check receiver.acceptPayment(channel, asset, payer.address, payment).isErr
