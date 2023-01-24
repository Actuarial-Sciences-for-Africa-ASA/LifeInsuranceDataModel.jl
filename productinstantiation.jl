using Revise, LifeInsuranceDataModel, TimeZones, SearchLight

prs = prsection(2, now(tz"UTC"), now(tz"UTC"))
pidrolemap = Dict(1 => 1, 2 => 2)
partnerrolemap::Dict{Integer,PartnerSection} = Dict()
for key in keys(pidrolemap)
    partnerrolemap[key] = psection(pidrolemap[key], now(tz"UTC"), now(tz"UTC"))
end

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

instpr = instantiate_product(prs, partnerrolemap)
