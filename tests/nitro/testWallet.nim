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
  var channel: ChannelId

  setup:
    wallet = Wallet.init(key)
    channel = wallet.openLedgerChannel(hub, chainId, nonce, asset, amount)

  test "sets correct channel definition":
    let definition = wallet[channel].get.state.channel
    check definition.chainId == chainId
    check definition.nonce == nonce
    check definition.participants == @[wallet.address, hub]

  test "provides correct outcome":
    let outcome = wallet[channel].get.state.outcome
    let destination = wallet.address.toDestination
    check outcome == Outcome.init(asset, {destination: amount})

  test "signs the state":
    let state = wallet[channel].get.state
    let signatures = wallet[channel].get.signatures
    check signatures == @{wallet.address: key.sign(state)}

  test "sets app definition and app data to zero":
    check wallet[channel].get.state.appDefinition == EthAddress.zero
    check wallet[channel].get.state.appData.len == 0

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
    check wallet[channel].get.state == signed.state

  test "signs the channel state":
    let channel = wallet.acceptChannel(signed).get
    let expectedSignatures = @{wallet.address: key.sign(signed.state)}
    check wallet[channel].get.signatures == expectedSignatures

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
