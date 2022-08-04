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
export ContractSection, ProductItemSection, PartnerSection, TariffSection, csection, pisection, tsection, psection, load_model
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

@kwdef mutable struct ContractPartnerReference
    rev::ContractPartnerRefRevision = TariffItemContractPartnerRefRevision()
    ref::PartnerSection = PartnerSection()
end

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

function get_revision(
    ctype::Type{CT},
    rtype::Type{RT},
    hid::DbId,
    vid::DbId,
) where {CT<:Component,RT<:ComponentRevision}
    find(
        rtype,
        SQLWhereExpression(
            "ref_component=? and ref_valid  @> BIGINT ?",
            find(ctype, SQLWhereExpression("ref_history=?", hid))[1].id,
            vid,
        ),
    )[1]
end

function get_revision(
    rtype::Type{RT},
    cid::DbId,
    vid::DbId,
) where {RT<:ComponentRevision}
    find(
        rtype,
        SQLWhereExpression(
            "ref_component=? and ref_valid  @> BIGINT ?",
            cid,
            vid
        ),
    )[1]
end

function pisection(history_id::Integer, version_id::Integer, tsdb_validfrom, tsworld_validfrom)::Vector{ProductItemSection}
    pis = find(ProductItem, SQLWhereExpression(
        "ref_history = BIGINT ? ", DbId(history_id)))
    map(pis) do pi
        let pir = get_revision(
                ProductItemRevision,
                pi.id,
                DbId(version_id),
            ),
            trs = find(TariffItem, SQLWhereExpression("ref_history = BIGINT ? and ref_super = BIGINT ? ", DbId(history_id), pi.id)),
            pitrs = map(trs) do tr
                let trr = get_revision(
                        TariffItemRevision,
                        tr.id,
                        DbId(version_id)
                    ),
                    ts = tsection(trr.ref_tariff.value, tsdb_validfrom, tsworld_validfrom),
                    pitrprs = find(TariffItemPartnerRef, SQLWhereExpression("ref_history = BIGINT ? and ref_super = BIGINT ? ", DbId(history_id), tr.id)),
                    pitrprrs = map(pitrprs) do pr
                        let prr = get_revision(
                                TariffItemPartnerRefRevision,
                                pr.id,
                                DbId(version_id)
                            ),
                            ps = psection(prr.ref_partner.value, tsdb_validfrom, tsworld_validfrom)

                            TariffItemPartnerReference(prr, ps)
                        end
                    end

                    TariffItemSection(TariffItemTariffReference(trr, ts), pitrprrs)
                end
            end

            ProductItemSection(
                revision=pir,
                tariff_items=pitrs
            )



        end




    end
end

function csection(contract_id::Integer, tsdb_validfrom, tsworld_validfrom)::ContractSection
    connect()
    history_id = find(Contract, SQLWhereExpression("id=?", DbId(contract_id)))[1].ref_history.value
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom).value
    ContractSection(
        ref_history=DbId(history_id),
        ref_version=DbId(version_id),
        revision=get_revision(
            Contract,
            ContractRevision,
            DbId(history_id),
            DbId(version_id),
        ),
        partner_refs=
        let cprrs = find(ContractPartnerRef, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
            map(cprrs) do cprr
                let cprr = get_revision(
                        ContractPartnerRefRevision,
                        cprr.id,
                        DbId(version_id)
                    ),
                    ps = psection(cprr.ref_partner.value, tsdb_validfrom, tsworld_validfrom)

                    ContractPartnerReference(cprr, ps)
                end
            end
        end,
        product_items=pisection(history_id, version_id, tsdb_validfrom, tsworld_validfrom),
        ref_entities=Dict{DbId,Union{PartnerSection,ContractSection,TariffSection}}(),
    )
end

function psection(partner_id::Integer, tsdb_validfrom, tsworld_validfrom)::PartnerSection
    connect()
    history_id = find(Partner, SQLWhereExpression("id=?", DbId(partner_id)))[1].ref_history
    version_id = findversion(history_id, tsdb_validfrom, tsworld_validfrom).value
    PartnerSection(
        revision=get_revision(
            Partner,
            PartnerRevision,
            DbId(history_id),
            DbId(version_id),
        ),
    )
end

function tsection(tariff_id::Integer, tsdb_validfrom, tsworld_validfrom)::TariffSection
    connect()
    history_id = find(Tariff, SQLWhereExpression("id=?", DbId(tariff_id)))[1].ref_history
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom).value
    TariffSection(
        revision=get_revision(
            Tariff,
            TariffRevision,
            DbId(history_id),
            DbId(version_id),
        ),
    )
end

function prsection(product_id::Integer, tsdb_validfrom, tsworld_validfrom)::ProductSection
    connect()
    history_id = find(Product, SQLWhereExpression("id=?", DbId(product_id)))[1].ref_history
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom).value
    ProductSection(
        revision=get_revision(
            Product,
            ProductRevision,
            DbId(history_id),
            DbId(version_id)),
        parts=let pts = find(ProductPart, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
            map(pts) do pt
                let ptr = get_revision(
                        ProductPartRevision,
                        pt.id,
                        DbId(version_id)
                    ),
                    ref = tsection(ptr.ref_tariff.value, tsdb_validfrom, tsworld_validfrom)

                    ProductPartSection(ptr, ref)
                end
            end
        end,
    )
end
function history_forest(history_id::Int)
    connect()
    BitemporalPostgres.Node(ValidityInterval(), mkforest(DbId(history_id)))
end

function get_contracts()
    connect()
    find(Contract)
end

function connect()
    try
        SearchLight.connection()
    catch e
        SearchLight.Configuration.load() |> SearchLight.connect
    end
end

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

function load_model()
    SearchLight.Configuration.load() |> SearchLight.connect
    SearchLight.Migrations.create_migrations_table()
    DDL.up()
    load_roles()
end

end #module
