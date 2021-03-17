import ../basics
import ../protocol

include questionable/errorban

type
  SignedState* = object
    state*: State
    signatures*: seq[(EthAddress, Signature)]

func hasParticipant*(signed: SignedState, participant: EthAddress): bool =
  signed.state.channel.participants.contains(participant)

func verifySignatures*(signed: SignedState): bool =
  for (participant, signature) in signed.signatures:
    if not signed.hasParticipant(participant):
      return false
    if not signature.verify(signed.state, participant):
      return false
  true
