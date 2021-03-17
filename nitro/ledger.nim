import ./basics
import ./signedstate
import ./protocol

func startLedger*(me: EthAddress,
                  hub: EthAddress,
                  chainId: UInt256,
                  nonce: UInt48,
                  asset: EthAddress,
                  amount: UInt256): SignedState =
  SignedState(
    state: State(
      channel: ChannelDefinition(
        chainId: chainId,
        participants: @[me, hub],
        nonce: nonce
      ),
      outcome: Outcome.init(asset, {me.toDestination: amount})
    )
  )
