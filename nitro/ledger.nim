import ./basics
import ./channelupdate
import ./protocol

proc startLedger*(me: EthAddress,
                  hub: EthAddress,
                  chainId: UInt256,
                  nonce: UInt48,
                  asset: EthAddress,
                  amount: UInt256): ChannelUpdate =
  ChannelUpdate(
    state: State(
      channel: ChannelDefinition(
        chainId: chainId,
        participants: @[me, hub],
        nonce: nonce
      ),
      outcome: Outcome.init(asset, {me.toDestination: amount})
    )
  )
