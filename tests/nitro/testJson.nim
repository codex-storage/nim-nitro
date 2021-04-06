import ./basics

suite "json serialization":

  let payment = SignedState.example()

  test "serializes signed states to json":
    check payment.toJson.len > 0

  test "deserializes signed state":
    check SignedState.fromJson(payment.toJson) == payment.some

  test "returns none when deserializing invalid json":
    let invalid = "{"
    check SignedState.fromJson(invalid).isNone

  test "returns none when json cannot be converted to signed state":
    let invalid = "{}"
    check SignedState.fromJson(invalid).isNone
