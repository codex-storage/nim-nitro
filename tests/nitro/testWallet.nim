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
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, amount)

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
    check signatures == @{wallet.address: key.sign(state)}

  test "sets app definition and app data to zero":
    check wallet.state(channel).get.appDefinition == EthAddress.zero
    check wallet.state(channel).get.appData.len == 0

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
    let expectedSignatures = @{wallet.address: key.sign(signed.state)}
    check wallet.signatures(channel).get == expectedSignatures

  test "fails when wallet address is not a participant":
    let wrongParticipants = seq[EthAddress].example
    signed.state.channel.participants = wrongParticipants
    check wallet.acceptChannel(signed).isErr

  test "fails when signatures are incorrect":
    let otherKey = PrivateKey.random()
    let otherWallet = Wallet.init(otherKey)
    let wrongAddress = EthAddress.example
    signed.state.channel.participants &= @[otherWallet.address]
    signed.signatures = @{wrongAddress: otherKey.sign(signed.state)}
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
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 100.u256)

    check wallet.pay(channel, asset, hub, 1.u256).isOk
    check wallet.balance(channel, asset, me) == 99.u256
    check wallet.balance(channel, asset, hub) == 1.u256

    check wallet.pay(channel, asset, hub, 2.u256).isOk
    check wallet.balance(channel, asset, me) == 97.u256
    check wallet.balance(channel, asset, hub) == 3.u256

  test "paying updates signatures":
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 100.u256)
    check wallet.pay(channel, asset, hub, 1.u256).isOk
    let expectedSignature = key.sign(wallet.state(channel).get)
    check wallet.signature(channel, wallet.address) == expectedSignature.some

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
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, 1.u256)
    check wallet.pay(channel, asset, hub, 1.u256).isOk
    check wallet.pay(channel, asset, hub, 1.u256).isErr
