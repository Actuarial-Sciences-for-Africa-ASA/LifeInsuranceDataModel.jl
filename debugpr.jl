using BitemporalPostgres
using LifeInsuranceDataModel
using SearchLight
using SearchLightPostgreSQL
using TimeZones
SearchLight.Configuration.load() |> SearchLight.connect

pid = 1
h = find(Product, SQLWhereExpression("id =?", pid))[1].ref_history
vi = find(ValidityInterval, SQLWhereExpression("ref_history=?", h), order=["ValidityInterval.id"])[1];
txntime = vi.tsdb_validfrom
reftime = vi.tsworld_validfrom

prsection(pid, txntime, reftime)