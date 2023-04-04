using BitemporalPostgres
using LifeInsuranceDataModel
using SearchLight
using SearchLightPostgreSQL
using TimeZones
ENV["SEARCHLIGHT_USERNAME"] = "postgres"
ENV["SEARCHLIGHT_PASSWORD"] = "postgres"
SearchLight.Configuration.load() |> SearchLight.connect
id = 4
h = find(Tariff, SQLWhereExpression("id =?", id))[1].ref_history
vi = find(ValidityInterval, SQLWhereExpression("ref_history=?", h), order=["ValidityInterval.id"])[1];
txntime = vi.tsdb_validfrom
reftime = vi.tsworld_validfrom

section = tsection(id, txntime, reftime)
println(section)
