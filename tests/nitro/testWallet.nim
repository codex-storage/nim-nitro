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

  test "creates a new upcoming state":
    check channel.latest.isNone
    check channel.upcoming.isSome

  test "sets correct channel definition":
    let definition = channel.upcoming?.state?.channel
    check definition?.chainId == chainId.some
    check definition?.nonce == nonce.some
    check definition?.participants == @[wallet.address, hub].some

  test "provides correct outcome":
    let outcome = channel.upcoming?.state?.outcome
    let destination = wallet.address.toDestination
    check outcome == Outcome.init(asset, {destination: amount}).some

  test "signs the upcoming state":
    let state = channel.upcoming?.state
    let signatures = channel.upcoming?.signatures
    check signatures == @{wallet.address: key.sign(state.get)}.some

  test "sets app definition and app data to zero":
    check channel.upcoming?.state?.appDefinition == EthAddress.zero.some
    check channel.upcoming?.state?.appData?.len == 0.some

  test "updates the list of channels":
    check wallet.channels == @[channel]

