import ../basics
import ../protocol

include questionable/errorban

type
  SignedState* = object
    state*: State
    signatures*: Signatures
  Signatures* = seq[(EthAddress, Signature)]

func hasParticipant*(signed: SignedState, participant: EthAddress): bool =
  signed.state.channel.participants.contains(participant)

func isSignedBy*(signed: SignedState, account: EthAddress): bool =
  for (signer, signature) in signed.signatures:
    if signer == account and signature.verify(signed.state, signer):
      return true
  false

func verifySignatures*(signed: SignedState): bool =
  for (participant, signature) in signed.signatures:
    if not signed.hasParticipant(participant):
      return false
    if not signature.verify(signed.state, participant):
      return false
  true
