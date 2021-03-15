import ./basics

suite "nitro wallet":

  let key = PrivateKey.random()
  let asset = EthAddress.example
  let amount = 42.u256

  test "wallet can be created from private key":
    let wallet = Wallet.init(key)
    check wallet.address == key.toPublicKey.toAddress

  test "opens ledger channel":
    let wallet = Wallet.init(key)
    let me = wallet.address.toDestination
    let channel = wallet.openLedger(asset, amount)
    let expectedOutcome = Outcome.init(asset, {me: amount})
    let expectedState = State(outcome: expectedOutcome)
    let expectedSignatures = @{wallet.address: key.sign(expectedState)}
    check channel.latest.isNone
    check channel.upcoming?.state == expectedState.some
    check channel.upcoming?.signatures == expectedSignatures.some

