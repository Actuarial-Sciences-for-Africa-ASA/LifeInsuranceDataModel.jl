module LifeInsuranceDataModel

import Base: @kwdef
import TimeZones
using TimeZones
import ToStruct
using ToStruct
import JSON
using JSON
import SearchLight
using SearchLight
import BitemporalPostgres
using BitemporalPostgres
include("DDL.jl")
using .DDL
include("InsuranceContracts.jl")
using .InsuranceContracts
export Contract,
    ContractRevision,
    ContractPartnerRole,
    ContractPartnerRef,
    ContractPartnerRefRevision,
    csection,
    history_forest,
    psection,
    ProductItem,
    ProductItemRevision,
    TariffItemRole,
    TariffItem,
    TariffItemRevision,
    TariffItemPartnerRole,
    TariffItemPartnerRef,
    TariffItemPartnerRefRevision,
    ProductSection,
    TariffSection,
    tsection
include("InsurancePartners.jl")
using .InsurancePartners

export Partner, PartnerRevision
include("InsuranceProducts.jl")
using .InsuranceProducts
include("InsuranceTariffs.jl")
using .InsuranceTariffs

export Product, ProductRevision, ProductPart, ProductPartRevision, ProductPartRole, Tariff, TariffRevision
export ContractSection, ProductItemSection, PartnerSection, TariffItemSection, TariffSection, csection, pisection, tsection, psection, load_model
export ProductSection, ProductPartSection, prsection

""""
PartnerSection

    is a section (see above) of a Partner entity

"""
@kwdef mutable struct PartnerSection
    tsdb_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    tsw_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    ref_history::SearchLight.DbId = DbId(InfinityKey)
    ref_version::SearchLight.DbId = MaxVersion
    revision::PartnerRevision = PartnerRevision()
end

"""
TariffSection 

is a section (see above) of a Tariff entity
"""
@kwdef mutable struct TariffSection
    tsdb_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    tsw_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    ref_history::SearchLight.DbId = DbId(InfinityKey)
    ref_version::SearchLight.DbId = MaxVersion
    revision::TariffRevision = TariffRevision()
end

"""
ProductPartSection 

is a section (see above) of a ProductPart entity
"""
@kwdef mutable struct ProductPartSection
    revision::ProductPartRevision = ProductPartRevision()
    ref::TariffSection = TariffSection()
end

"""
ProductSection 

is a section (see above) of a Product entity
"""
@kwdef mutable struct ProductSection
    tsdb_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    tsw_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    ref_history::SearchLight.DbId = DbId(InfinityKey)
    ref_version::SearchLight.DbId = MaxVersion
    revision::ProductRevision = ProductRevision()
    parts::Vector{ProductPartSection} = []
end

"""
TariffItemPartnerReference is a reference from a TariffItem to a Partner entity
For instance, typically an insured person
"""
@kwdef mutable struct TariffItemPartnerReference
    rev::TariffItemPartnerRefRevision = TariffItemPartnerRefRevision()
    ref::PartnerSection = PartnerSection()
end


"""
TariffItemTariffReference is a reference from a TariffItem to a Tariff entity
"""
@kwdef mutable struct TariffItemTariffReference
    rev::TariffItemRevision = TariffItemRevision()
    ref::TariffSection = TariffSection()
end

"""
TariffItemSection is a section (see above) of a TariffItem component
"""
@kwdef mutable struct TariffItemSection
    tariff_ref::TariffItemTariffReference = TariffItemTariffReference()
    partner_refs::Vector{TariffItemPartnerReference} = [TariffItemPartnerReference()]
end

"""
ProductItemSection is a section (see above) of a ProductItem component
"""
@kwdef mutable struct ProductItemSection
    revision::ProductItemRevision = ProductItemRevision(position=0)
    tariff_items::Vector{TariffItemSection} = [TariffItemSection]
end

"""
ContractPartnerReference
    holds attributes of the reference from contract and a partner section
"""
@kwdef mutable struct ContractPartnerReference
    rev::ContractPartnerRefRevision = TariffItemContractPartnerRefRevision()
    ref::PartnerSection = PartnerSection()
end

"""
ContractSection
    ContractSection is a section (see above) of a contract entity
"""
@kwdef mutable struct ContractSection
    tsdb_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    tsw_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    ref_history::SearchLight.DbId = DbId(InfinityKey)
    ref_version::SearchLight.DbId = MaxVersion
    revision::ContractRevision = ContractRevision()
    partner_refs::Vector{ContractPartnerReference} = [ContractPartnerReference]
    product_items::Vector{ProductItemSection} = [ProductItemSection()]
    ref_entities::Dict{DbId,Union{PartnerSection,ContractSection,TariffSection}} =
        Dict{DbId,Union{PartnerSection,ContractSection,TariffSection}}()
end

"""
function pisection(history_id::Integer, version_id::Integer, tsdb_validfrom, tsworld_validfrom)::Vector{ProductItemSection}

    pisection retrieves the vector of a contract's productitem sections
"""
function pisection(history_id::Integer, version_id::Integer, tsdb_validfrom, tsworld_validfrom)::Vector{ProductItemSection}
    pis = find(ProductItem, SQLWhereExpression(
        "ref_history = BIGINT ? ", DbId(history_id)))
    collect(Iterators.flatten(map(pis) do pi
        map(get_revisionIfAny(
            ProductItemRevision,
            pi.id,
            DbId(version_id),
        )) do pir
            let trs = find(TariffItem, SQLWhereExpression("ref_history = BIGINT ? and ref_super = BIGINT ? ", DbId(history_id), pi.id)),
                pitrs = map(trs) do tr
                    let trr = get_revision(
                            TariffItemRevision,
                            tr.id,
                            DbId(version_id)
                        ),
                        ts = tsection(trr.ref_tariff.value, tsdb_validfrom, tsworld_validfrom),
                        pitrprs = find(TariffItemPartnerRef, SQLWhereExpression("ref_history = BIGINT ? and ref_super = BIGINT ? ", DbId(history_id), tr.id)),
                        pitrprrs = collect(Iterators.flatten(
                            map(pitrprs) do pr
                                map(get_revisionIfAny(
                                    TariffItemPartnerRefRevision,
                                    pr.id,
                                    DbId(version_id)
                                )) do prr
                                    let ps = psection(prr.ref_partner.value, tsdb_validfrom, tsworld_validfrom)

                                        TariffItemPartnerReference(prr, ps)
                                    end
                                end
                            end))

                        TariffItemSection(TariffItemTariffReference(trr, ts), pitrprrs)
                    end
                end

                ProductItemSection(
                    revision=pir,
                    tariff_items=pitrs
                )
            end
        end
    end))
end

"""
csection(contract_id::Integer, tsdb_validfrom, tsworld_validfrom)::ContractSectio

    csection retrieves the section of a contract or throws NoVersionFound 
"""
function csection(contract_id::Integer, tsdb_validfrom, tsworld_validfrom)::ContractSection
    connect()
    history_id = find(Contract, SQLWhereExpression("id=?", DbId(contract_id)))[1].ref_history.value
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom).value
    let cr = get_revision(
            Contract,
            ContractRevision,
            DbId(history_id),
            DbId(version_id),
        )
        ContractSection(
            ref_history=DbId(history_id),
            ref_version=DbId(version_id),
            revision=cr,
            partner_refs=
            let cprs = find(ContractPartnerRef, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
                collect(Iterators.flatten(map(cprs) do cpr
                    map(get_revisionIfAny(
                        ContractPartnerRefRevision,
                        cpr.id,
                        DbId(version_id)
                    )) do cprr
                        let ps = psection(cprr.ref_partner.value, tsdb_validfrom, tsworld_validfrom)

                            ContractPartnerReference(cprr, ps)
                        end
                    end
                end))
            end,
            product_items=pisection(history_id, version_id, tsdb_validfrom, tsworld_validfrom),
            ref_entities=Dict{DbId,Union{PartnerSection,ContractSection,TariffSection}}(),
        )
    end
end

"""
psection(partner_id::Integer, tsdb_validfrom, tsworld_validfrom)::PartnerSection

    psection retrieves a section of a partner  or throws NoVersionFound

"""
function psection(partner_id::Integer, tsdb_validfrom, tsworld_validfrom)::PartnerSection
    connect()
    history_id = find(Partner, SQLWhereExpression("id=?", DbId(partner_id)))[1].ref_history
    version_id = findversion(history_id, tsdb_validfrom, tsworld_validfrom).value
    let pr = get_revision(
            Partner,
            PartnerRevision,
            DbId(history_id),
            DbId(version_id),
        )
        PartnerSection(
            revision=pr,
        )
    end
end

"""
tsection(tariff_id::Integer, tsdb_validfrom, tsworld_validfrom)::TariffSection

    tsection retrieves a section of a tariff or throws NoVersionFound

"""
function tsection(tariff_id::Integer, tsdb_validfrom, tsworld_validfrom)::TariffSection
    connect()
    history_id = find(Tariff, SQLWhereExpression("id=?", DbId(tariff_id)))[1].ref_history
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom).value
    let tr = get_revision(
            Tariff,
            TariffRevision,
            DbId(history_id),
            DbId(version_id),)
        TariffSection(
            revision=tr
        )
    end
end

"""
prsection(product_id::Integer, tsdb_validfrom, tsworld_validfrom)::ProductSection

    prsection retrieves a section of a product or throws NoVersionFound

"""
function prsection(product_id::Integer, tsdb_validfrom, tsworld_validfrom)::ProductSection
    connect()
    history_id = find(Product, SQLWhereExpression("id=?", DbId(product_id)))[1].ref_history
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom).value
    let pr = get_revision(
            Product,
            ProductRevision,
            DbId(history_id),
            DbId(version_id))
        ProductSection(
            revision=pr,
            parts=let pts = find(ProductPart, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
                collect(Iterators.flatten(map(pts) do pt
                    map(get_revisionIfAny(
                        ProductPartRevision,
                        pt.id,
                        DbId(version_id)
                    )) do ptr
                        let ref = tsection(ptr.ref_tariff.value, tsdb_validfrom, tsworld_validfrom)

                            ProductPartSection(ptr, ref)
                        end
                    end
                end))
            end
        )
    end
end

"""
history_forest(history_id::Int)
    history_forest retrieves a tree of ValidityIntervals see:[BitemporalPostgres Theory] (https://actuarial-sciences-for-africa-asa.github.io/BitemporalPostgres.jl/stable/api/theory/)
"""
function history_forest(history_id::Int)
    connect()
    BitemporalPostgres.Node(ValidityInterval(), mkforest(DbId(history_id)))
end

"""
get_contracts
    get_contracts retrieves all contract entities - search capabilities to be added 
"""
function get_contracts()
    connect()
    find(Contract)
end

"""
connect
    database connect as configured 
"""
function connect()
    SearchLight.connect(SearchLight.Configuration.load())
end

"""
load_roles
    create the role ids of the model's relations
"""
function load_roles()
    contractpartnerroles = map(["Policy Holder" "Premium Payer"]) do val
        save!(ContractPartnerRole(value=val))
    end
    tariffitempartnerroles = map(["Insured Person" "2nd Insured Person"]) do val
        save!(TariffItemPartnerRole(value=val))
    end
    tariffitemtariffroles = map(["Main Coverage - Life" "Supplementary Coverage - Occupational Disablity" "Supplementary Coverage - Terminal Illness" "Profit participation"]) do val
        save!(TariffItemRole(value=val))
    end

    productpartroles = map(["Main Coverage - Life" "Supplementary Coverage - Occupational Disablity" "Supplementary Coverage - Terminal Illness" "Profit participation"]) do val
        save!(ProductPartRole(value=val))
    end
end

"""
load_model
    create the DDL of the model
"""

function load_model()
    SearchLight.Configuration.load() |> SearchLight.connect
    SearchLight.Migrations.create_migrations_table()
    DDL.up()
    load_roles()
end

end #module
