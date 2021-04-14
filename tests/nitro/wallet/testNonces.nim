import ../basics
import pkg/nitro/wallet/nonces

suite "nonces":

  let chainId = UInt256.example
  let participants = seq[EthAddress].example

  var nonces: Nonces

  setup:
    nonces = Nonces()

  test "nonces start at 0":
    check nonces.getNonce(chainId, participants) == 0

  test "nonces increase by 1":
    nonces.incNonce(0, chainId, participants)
    check nonces.getNonce(chainId, participants) == 1
    nonces.incNonce(1, chainId, participants)
    check nonces.getNonce(chainId, participants) == 2

  test "nonces do not decrease":
    nonces.incNonce(100, chainId, participants)
    check nonces.getNonce(chainId, participants) == 101
    nonces.incNonce(0, chainId, participants)
    check nonces.getNonce(chainId, participants) == 102

  test "nonces are different when participants differ":
    let otherParticipants = seq[EthAddress].example
    nonces.incNonce(0, chainId, participants)
    check nonces.getNonce(chainId, otherParticipants) == 0

  test "nonces are different when chain ids differ":
    let otherChainId = UInt256.example
    nonces.incNonce(0, chainId, participants)
    check nonces.getNonce(otherChainId, participants) == 0
