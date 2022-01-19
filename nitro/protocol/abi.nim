import pkg/contractabi
import ../basics

push: {.upraises:[].}

export basics
export contractabi

func encode*(encoder: var AbiEncoder, destination: Destination) =
  encoder.write(destination.toArray)
