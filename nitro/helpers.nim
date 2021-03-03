import std/options
import pkg/stew/results

include ./noerrors

export options
export results

proc toOption*[T, E](res: Result[T, E]): Option[T] =
  if res.isOk:
    res.unsafeGet().some
  else:
    T.none
