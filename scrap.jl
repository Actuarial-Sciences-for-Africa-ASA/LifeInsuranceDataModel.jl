using LifeInsuranceDataModel

tariff_id = 5
activeTransaction = 0
tsdb_validfrom = now(tz"UTC")
tsworld_validfrom = now(tz"UTC")

LifeInsuranceDataModel.connect()

history_id = find(Tariff, SQLWhereExpression("id=?", DbId(tariff_id)))[1].ref_history
version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom, activeTransaction == 1 ? 0 : 1).value
let tr = get_revision(Tariff, TariffRevision, DbId(history_id), DbId(version_id))
    trpr = collect(Iterators.flatten(map(find(TariffPartnerRole, SQLWhereExpression("ref_super=?", tr.ref_component))) do tpr
        get_revisionIfAny(TariffPartnerRoleRevision, DbId(tpr.id), DbId(version_id))
    end))
    TariffSection(revision=tr, partner_roles=trpr)
end
