import ../basics
import ../protocol

include questionable/errorban

type
  SignedState* = object
    state*: State
    signatures*: seq[Signature]

func hasParticipant*(signed: SignedState, participant: EthAddress): bool =
  signed.state.channel.participants.contains(participant)

func isSignedBy*(signed: SignedState, account: EthAddress): bool =
  for signature in signed.signatures:
    if signer =? signature.recover(signed.state):
      if signer == account:
        return true
  false

func verifySignatures*(signed: SignedState): bool =
  for signature in signed.signatures:
    if signer =? signature.recover(signed.state):
      if not signed.hasParticipant(signer):
        return false
    else:
      return false
  true
