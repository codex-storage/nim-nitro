import ./basics

suite "wallet":

  test "wallet is created from private key":
    let key = EthPrivateKey.random()
    let wallet = Wallet.init(key)
    check wallet.publicKey == key.toPublicKey
    check wallet.address == key.toPublicKey.toAddress
    check wallet.destination == key.toPublicKey.toAddress.toDestination

suite "wallet: opening ledger channel":

  let key = EthPrivateKey.random()
  let asset = EthAddress.example
  let amount = 42.u256
  let hub = EthAddress.example
  let chainId = UInt256.example
  let nonce = UInt48.example

  var wallet: Wallet
  var channel: ChannelId

  setup:
    wallet = Wallet.init(key)
    channel = !wallet.openLedgerChannel(hub, chainId, nonce, asset, amount)

  test "sets correct channel definition":
    let definition = (!wallet.state(channel)).channel
    check definition.chainId == chainId
    check definition.nonce == nonce
    check definition.participants == @[wallet.address, hub]

  test "uses consecutive nonces when none is provided":
    channel = !wallet.openLedgerChannel(hub, chainId, asset, amount)
    check (!wallet.state(channel)).channel.nonce == nonce + 1
    channel = !wallet.openLedgerChannel(hub, chainId, asset, amount)
    check (!wallet.state(channel)).channel.nonce == nonce + 2

  test "provides correct outcome":
    let outcome = (!wallet.state(channel)).outcome
    check outcome == Outcome.init(asset, {wallet.destination: amount})

  test "signs the state":
    let state = !wallet.state(channel)
    let signatures = !wallet.signatures(channel)
    check signatures == @[key.sign(state)]

  test "sets app definition and app data to zero":
    check (!wallet.state(channel)).appDefinition == EthAddress.zero
    check (!wallet.state(channel)).appData.len == 0

  test "does not allow opening a channel that already exists":
    check wallet.openLedgerChannel(hub, chainId, nonce, asset, amount).isFailure

suite "wallet: accepting incoming channel":

  let key = EthPrivateKey.random()
  var wallet: Wallet
  var signed: SignedState

  setup:
    wallet = Wallet.init(key)
    signed = SignedState(state: State.example)
    signed.state.channel.participants &= @[wallet.address]

  test "returns the new channel id":
    let channel = !wallet.acceptChannel(signed)
    check !wallet.state(channel) == signed.state

  test "signs the channel state":
    let channel = !wallet.acceptChannel(signed)
    let expectedSignatures = @[key.sign(signed.state)]
    check !wallet.signatures(channel) == expectedSignatures

  test "fails when wallet address is not a participant":
    let wrongParticipants = seq[EthAddress].example
    signed.state.channel.participants = wrongParticipants
    check wallet.acceptChannel(signed).isFailure

  test "fails when signatures are incorrect":
    signed.signatures = @[key.sign(State.example)]
    check wallet.acceptChannel(signed).isFailure

  test "fails when channel with this id already exists":
    check wallet.acceptChannel(signed).isSuccess
    check wallet.acceptChannel(signed).isFailure

suite "wallet: making payments":

  let key = EthPrivateKey.random()
  let asset = EthAddress.example
  let hub = EthAddress.example
  let chainId = UInt256.example
  let nonce = UInt48.example

  var wallet: Wallet
  var channel: ChannelId

  test "paying updates the channel state":
    wallet = Wallet.init(key)
    channel = !wallet.openLedgerChannel(hub, chainId, nonce, asset, 100.u256)

    check wallet.pay(channel, asset, hub, 1.u256).isSuccess
    check wallet.balance(channel, asset) == 99.u256
    check wallet.balance(channel, asset, hub) == 1.u256

    check wallet.pay(channel, asset, hub, 2.u256).isSuccess
    check wallet.balance(channel, asset) == 97.u256
    check wallet.balance(channel, asset, hub) == 3.u256

  test "paying updates signatures":
    wallet = Wallet.init(key)
    channel = !wallet.openLedgerChannel(hub, chainId, nonce, asset, 100.u256)
    check wallet.pay(channel, asset, hub, 1.u256).isSuccess
    let expectedSignature = key.sign(!wallet.state(channel))
    check wallet.signature(channel, wallet.address) == expectedSignature.some

  test "pay returns the updated signed state":
    wallet = Wallet.init(key)
    channel = !wallet.openLedgerChannel(hub, chainId, nonce, asset, 42.u256)
    let updated = wallet.pay(channel, asset, hub, 1.u256).option
    check updated.?state == wallet.state(channel)
    check updated.?signatures == wallet.signatures(channel)

  test "payment fails when channel not found":
    wallet = Wallet.init(key)
    check wallet.pay(channel, asset, hub, 1.u256).isFailure

  test "payment fails when asset not found":
    wallet = Wallet.init(key)
    var state = State.example
    state.channel.participants &= wallet.address
    channel = !wallet.acceptChannel(SignedState(state: state))
    check wallet.pay(channel, asset, hub, 1.u256).isFailure

  test "payment fails when payer has no allocation":
    wallet = Wallet.init(key)
    var state: State
    state.channel = ChannelDefinition(participants: @[wallet.address])
    state.outcome = Outcome.init(asset, @[])
    channel = !wallet.acceptChannel(SignedState(state: state))
    check wallet.pay(channel, asset, hub, 1.u256).isFailure

  test "payment fails when payer has insufficient funds":
    wallet = Wallet.init(key)
    channel = !wallet.openLedgerChannel(hub, chainId, nonce, asset, 1.u256)
    check wallet.pay(channel, asset, hub, 1.u256).isSuccess
    check wallet.pay(channel, asset, hub, 1.u256).isFailure

suite "wallet: accepting payments":

  let payerKey, receiverKey = EthPrivateKey.random()
  let asset = EthAddress.example
  let chainId = UInt256.example
  let nonce = UInt48.example

  var payer, receiver: Wallet
  var channel: ChannelId

  setup:
    payer = Wallet.init(payerKey)
    receiver = Wallet.init(receiverKey)
    channel = !payer.openLedgerChannel(
      receiver.address, chainId, nonce, asset, 100.u256)
    let update = !payer.latestSignedState(channel)
    discard receiver.acceptChannel(update)

  test "updates channel state":
    let payment = !payer.pay(channel, asset, receiver.address, 42.u256)
    check receiver.acceptPayment(channel, asset, payer.address, payment).isSuccess
    check receiver.balance(channel, asset) == 42.u256

  test "fails when receiver balance is decreased":
    let payment1 = !payer.pay(channel, asset, receiver.address, 10.u256)
    let payment2 = !payer.pay(channel, asset, receiver.address, 10.u256)
    check receiver.acceptPayment(channel, asset, payer.address, payment1).isSuccess
    check receiver.acceptPayment(channel, asset, payer.address, payment2).isSuccess
    check receiver.acceptPayment(channel, asset, payer.address, payment1).isFailure
    check receiver.balance(channel, asset) == 20

  test "fails when the total supply of the asset changes":
    var payment = !payer.pay(channel, asset, receiver.address, 10.u256)
    var balances = !payment.state.outcome.balances(asset)
    balances[payer.destination] += 10.u256
    payment.state.outcome.update(asset, balances)
    check receiver.acceptPayment(channel, asset, payer.address, payment).isFailure

  test "fails without a signature":
    var payment = !payer.pay(channel, asset, receiver.address, 10.u256)
    payment.signatures = @[]
    check receiver.acceptPayment(channel, asset, payer.address, payment).isFailure

  test "fails with an incorrect signature":
    var payment = !payer.pay(channel, asset, receiver.address, 10.u256)
    payment.signatures = @[Signature.example]
    check receiver.acceptPayment(channel, asset, payer.address, payment).isFailure

  test "fails when channel is unknown":
    let newChannel = !payer.openLedgerChannel(
      receiver.address, chainId, nonce + 1, asset, 100.u256)
    let payment = !payer.pay(newChannel, asset, receiver.address, 10.u256)
    check receiver.acceptPayment(newChannel, asset, payer.address, payment).isFailure

  test "fails when payment does not match channel":
    let newChannel = !payer.openLedgerChannel(
      receiver.address, chainId, nonce + 1, asset, 100.u256)
    let payment = !payer.pay(newChannel, asset, receiver.address, 10.u256)
    check receiver.acceptPayment(channel, asset, payer.address, payment).isFailure

  test "fails when state is updated in unrelated areas":
    var payment = !payer.pay(channel, asset, receiver.address, 10.u256)
    payment.state.appDefinition = EthAddress.example
    payment.signatures = @[payerKey.sign(payment.state)]
    check receiver.acceptPayment(channel, asset, payer.address, payment).isFailure

suite "wallet reference type":

  let asset = EthAddress.example
  let amount = 42.u256
  let chainId = UInt256.example

  test "wallet can also be used as a reference type":
    let wallet1 = WalletRef.new(EthPrivateKey.random())
    let wallet2 = WalletRef.new(EthPrivateKey.random())
    let address1 = wallet1.address
    let address2 = wallet2.address
    let channel = !wallet1.openLedgerChannel(address2, chainId, asset, amount)
    check !wallet2.acceptChannel(!wallet1.latestSignedState(channel)) == channel
    let payment = !wallet1.pay(channel, asset, address2, amount)
    check wallet2.acceptPayment(channel, asset, address1, payment).isSuccess
