import std/options
import pkg/stew/results

export options
export results

{.push raises:[].}

proc toOption*[T, E](res: Result[T, E]): Option[T] =
  if res.isOk:
    res.value.some
  else:
    T.none
