import ./basics
import ./protocol

include questionable/errorban

type
  SignedState* = object
    state*: State
    signatures*: seq[(EthAddress, Signature)]

func participants*(signed: SignedState): seq[EthAddress] =
  signed.state.channel.participants

func verifySignatures*(signed: SignedState): bool =
  for (participant, signature) in signed.signatures:
    if not signed.participants.contains(participant):
      return false
    if not signature.verify(signed.state, participant):
      return false
  true
