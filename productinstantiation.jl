using Revise, LifeInsuranceDataModel, TimeZones, SearchLight

prs = prsection(1, now(tz"UTC"), now(tz"UTC"))
pidrolemap = Dict(1 => 1, 2 => 1)
partnerrolemap::Dict{Integer,PartnerSection} = Dict()
for key in keys(pidrolemap)
    partnerrolemap[key] = psection(pidrolemap[key], now(tz"UTC"), now(tz"UTC"))
end
roles = Set{Integer}();
map(prs.parts) do pt
    for r in pt.ref.partner_roles
        push!(roles, r.ref_role.value)
    end

end;
function instantiate_product(prs::ProductSection, partnerrolemap::Dict{Integer,PartnerSection})
    ts = map(prs.parts) do pt
        let tiprs = map(pt.ref.partner_roles) do r
                TariffItemPartnerReference(rev=TariffItemPartnerRefRevision(ref_role=r.ref_role.value),
                    ref=partnerrolemap[r.ref_role.value])
            end
            tir = TariffItemRevision(ref_role=pt.revision.ref_role, ref_tariff=pt.revision.ref_tariff)
            titr = TariffItemTariffReference(ref=pt.ref, rev=tir)
            TariffItemSection(tariff_ref=titr, partner_refs=tiprs)
        end
    end
    pir = ProductItemRevision(ref_product=prs.revision.ref_component)
    ProductItemSection(revision=pir, tariff_items=ts)
end

instantiate_product(prs, partnerrolemap)
