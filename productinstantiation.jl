using Revise, LifeInsuranceDataModel, TimeZones, SearchLight
prrolemap = Dict(1 => 1, 2 => 1)
partners = Dict{Integer,Any}()
for key in keys(prrolemap)
    partners[key] = psection(prrolemap[key], now(tz"UTC"), now(tz"UTC"))
end

prs = prsection(1, now(tz"UTC"), now(tz"UTC"))
ts = map(prs.parts) do pt
    let tiprs = map(pt.ref.partner_roles) do r
            TariffItemPartnerReference(rev=TariffItemPartnerRefRevision(ref_role=r.ref_role.value),
                ref=partners[1])
        end
        tir = TariffItemRevision(ref_role=pt.revision.ref_role, ref_tariff=pt.revision.ref_tariff)
        titr = TariffItemTariffReference(ref=pt.ref, rev=tir)
        TariffItemSection(tariff_ref=titr, partner_refs=tiprs)
    end
end
