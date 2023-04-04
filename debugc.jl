using BitemporalPostgres
using LifeInsuranceDataModel
using SearchLight
using SearchLightPostgreSQL
using TimeZones
SearchLight.Configuration.load() |> SearchLight.connect()
w = 1
m = 2
jointlifeRiskProduct = 2
h = find(Product, SQLWhereExpression("id =?", ?))[1].ref_history
txntime = vi.tsdb_validfrom
reftime = vi.tsworld_validfrom
vi = find(ValidityInterval, SQLWhereExpression("ref_history=?", h), order=["ValidityInterval.id"])[1];
txntime = vi.tsdb_validfrom
reftime = vi.tsworld_validfrom
prsection(jointlifeRiskProduct, txntime, reftime)