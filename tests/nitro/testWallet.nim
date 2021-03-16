import ./basics

suite "wallet":

  test "wallet can be created from private key":
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
  var channel: Channel

  setup:
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, amount)

  test "sets correct channel definition":
    let definition = channel.latest.state.channel
    check definition.chainId == chainId
    check definition.nonce == nonce
    check definition.participants == @[wallet.address, hub]

  test "provides correct outcome":
    let outcome = channel.latest.state.outcome
    let destination = wallet.address.toDestination
    check outcome == Outcome.init(asset, {destination: amount})

  test "signs the upcoming state":
    let state = channel.latest.state
    let signatures = channel.latest.signatures
    check signatures == @{wallet.address: key.sign(state)}

  test "sets app definition and app data to zero":
    check channel.latest.state.appDefinition == EthAddress.zero
    check channel.latest.state.appData.len == 0

  test "updates the list of channels":
    check wallet.channels == @[channel]

suite "wallet: accepting incoming channel":

  let key = PrivateKey.random()
  var wallet: Wallet
  var update: ChannelUpdate

  setup:
    wallet = Wallet.init(key)
    update = ChannelUpdate(state: State.example)
    update.state.channel.participants &= @[wallet.address]

  test "returns the new channel instance":
    let channel = wallet.acceptChannel(update).get
    check channel.latest.state == update.state

  test "updates the list of channels":
    let channel = wallet.acceptChannel(update).get
    check wallet.channels == @[channel]

  test "signs the channel state":
    let channel = wallet.acceptChannel(update).get
    let expectedSignatures = @{wallet.address: key.sign(update.state)}
    check channel.latest.signatures == expectedSignatures

  test "fails when wallet address is not a participant":
    let wrongParticipants = seq[EthAddress].example
    update.state.channel.participants = wrongParticipants
    check wallet.acceptChannel(update).isErr

  test "fails when signatures are incorrect":
    let otherKey = PrivateKey.random()
    let otherWallet = Wallet.init(otherKey)
    let wrongAddress = EthAddress.example
    update.state.channel.participants &= @[otherWallet.address]
    update.signatures = @{wrongAddress: otherKey.sign(update.state)}
    check wallet.acceptChannel(update).isErr
