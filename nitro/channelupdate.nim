import ./basics
import ./protocol

include questionable/errorban

type
  ChannelUpdate* = object
    state*: State
    signatures*: seq[(EthAddress, Signature)]

func participants*(update: ChannelUpdate): seq[EthAddress] =
  update.state.channel.participants

func verifySignatures*(update: ChannelUpdate): bool =
  for (participant, signature) in update.signatures:
    if not update.participants.contains(participant):
      return false
    if not signature.verify(update.state, participant):
      return false
  true
