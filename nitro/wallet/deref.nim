import std/macros

func identName(identDefs: NimNode): NimNode =
  identDefs.expectKind(nnkIdentDefs)
  identDefs[0]

func identType(identDefs: NimNode): NimNode =
  identDefs.expectKind(nnkIdentDefs)
  identDefs[^2]

func `identType=`(identDefs: NimNode, identType: NimNode) =
  identDefs.expectKind(nnkIdentDefs)
  identDefs[^2] = identType

func insertRef(function: NimNode) =
  function.expectKind(nnkFuncDef)
  var paramType = function.params[1].identType
  if paramType.kind == nnkVarTy:
    paramType = paramType[0]
  function.params[1].identType = newNimNode(nnkRefTy, paramType).add(paramType)

func paramNames(function: NimNode): seq[NimNode] =
  function.expectKind(nnkFuncDef)
  for i in 1..<function.params.len:
    result.add(function.params[i].identName)

func insertDeref(params: var seq[NimNode]) =
  params[0] = newNimNode(nnkBracketExpr, params[0]).add(params[0])

func derefOverload(function: NimNode): NimNode =
  function.expectKind(nnkFuncDef)
  var arguments = function.paramNames
  arguments.insertDeref()
  result = function.copyNimTree()
  result.insertRef()
  result.body = newCall(function.name, arguments)

macro deref*(function: untyped{nkFuncDef}): untyped =
  ## Creates an overload that dereferences the first argument of the function
  ## call. Roughly equivalent to the `implicitDeref` experimental feature of
  ## Nim.

  let overload = derefOverload(function)
  quote do:
    `function`
    `overload`
