import pkg/nimcrypto
import pkg/secp256k1
import pkg/stew/byteutils
import ../basics

suite "signature":

  test "signs state hashes":
    let state = State.example
    let privateKey = PrivateKey.random()
    let publicKey = privateKey.toPublicKey()

    let signature = privateKey.sign(state)

    let message = hashState(state)
    let data = "\x19Ethereum Signed Message:\n32".toBytes & @message
    let hash = keccak256.digest(data).data
    check recover(signature, SkMessage(hash)).tryGet() == publicKey

  test "recovers ethereum address from signature":
    let state1, state2 = State.example
    let key = PrivateKey.random()
    let address = key.toPublicKey.toAddress
    let signature = key.sign(state1)
    check recover(signature, state1) == address.some
    check recover(signature, state2) != address.some

  test "produces the same signatures as the javascript implementation":
    let state =State(
      channel: ChannelDefinition(
        chainId: 0x1.u256,
        nonce: 1,
        participants: @[
          EthAddress.parse("0x8a64E10FF40Bc9C90EA5750313dB5e036495c10E").get()
        ]
      ),
      outcome: Outcome(@[]),
      turnNum: 1,
      isFinal: false,
      appData: @[0'u8],
      appDefinition: EthAddress.default,
      challengeDuration: 5
    )
    let seckey = PrivateKey.parse(
      "41b0f5f91967dded8af487277874f95116094cc6004ac2b2169b5b6a87608f3e"
    ).get()
    let expected = Signature.parse(
      "9b966cf0065586d59c8b9eb475ac763c96ad8316b81061238f32968a631f9e21" &
      "251363c193c78c89b3eb2fec23f0ea5c3c72acff7d1f27430cfb84b9da9831fb" &
      "1c"
    ).get()
    check seckey.sign(state) == expected
