import std/tables
import std/sequtils
import ../basics
import ../protocol

include questionable/errorban

export tables

type
  Balances* = OrderedTable[Destination, UInt256]

func `balances`*(outcome: Outcome, asset: EthAddress): ?Balances =
  for assetOutcome in seq[AssetOutcome](outcome):
    if assetOutcome.assetHolder == asset:
      if assetOutcome.kind == allocationType:
        let allocation = assetOutcome.allocation
        let items = seq[AllocationItem](allocation)
        return items.toOrderedTable.some
  Balances.none

func `update`*(outcome: var Outcome, asset: EthAddress, table: Balances) =
  for assetOutcome in seq[AssetOutcome](outcome).mitems:
    if assetOutcome.assetHolder == asset:
      if assetOutcome.kind == allocationType:
        assetOutcome.allocation = Allocation(toSeq(table.pairs))

func move*(balances: var Balances,
           source: Destination,
           destination: Destination,
           amount: UInt256): ?!void =
  try:
    if balances[source] < amount:
      return void.failure "insufficient funds"

    balances[source] -= amount
    if (balances.contains(destination)):
      balances[destination] += amount
    else:
      balances[destination] = amount

    ok()
  except KeyError:
    void.failure "no funds"
