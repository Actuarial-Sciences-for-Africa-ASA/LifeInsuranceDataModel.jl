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
include("InsuranceTariffs.jl")
using .InsuranceTariffs
export Tariff, TariffRevision
export ContractSection, ProductItemSection, PartnerSection, TariffSection, csection, pisection, tsection, psection
export insurancecontracts_view


@kwdef mutable struct PartnerSection
    tsdb_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    tsw_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    ref_history::SearchLight.DbId = DbId(InfinityKey)
    ref_version::SearchLight.DbId = MaxVersion
    revision::PartnerRevision = PartnerRevision()
end


@kwdef mutable struct TariffSection
    tsdb_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    tsw_validfrom::TimeZones.ZonedDateTime = now(tz"UTC")
    ref_history::SearchLight.DbId = DbId(InfinityKey)
    ref_version::SearchLight.DbId = MaxVersion
    revision::TariffRevision = TariffRevision()
end

@kwdef mutable struct TariffItemPartnerReference
    rev::TariffItemPartnerRefRevision = TariffItemPartnerRefRevision()
    ref::PartnerSection = PartnerSection()
end

@kwdef mutable struct TariffItemTariffReference
    rev::TariffItemRevision = TariffItemRevision()
    ref::TariffSection = TariffSection()
end

@kwdef mutable struct TariffItemSection
    tariff_ref::TariffItemTariffReference = TariffItemTariffReference()
    partner_refs::Vector{TariffItemPartnerReference} = [TariffItemPartnerReference()]
end

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

function history_forest(history_id::Int)
    connect()
    BitemporalPostgres.Node(ValidityInterval(), mkforest(DbId(history_id),
        MaxDate,
        ZonedDateTime(1900, 1, 1, 0, 0, 0, 0, tz"UTC"),
        MaxDate,
    ))
end

function mkhdict(
    hid::DbId,
    tsdb_invalidfrom::ZonedDateTime,
    tsworld_validfrom::ZonedDateTime,
    tsworld_invalidfrom::ZonedDateTime,
)
    map(
        i::ValidityInterval -> Dict{String,Any}(
            "interval" => i,
            "shadowed" => Vector{Dict{String,Any}}(mkforest(hid, i.tsdb_validfrom, i.tsworld_validfrom, i.tsworld_invalidfrom),)
        ),
        find(
            ValidityInterval,
            SQLWhereExpression(
                "ref_history=? AND  upper(tsrdb)=? AND tstzrange(?,?) * tsrworld = tsrworld",
                hid,
                tsdb_invalidfrom,
                tsworld_validfrom,
                tsworld_invalidfrom,
            ),
        ),
    )
end

function renderhistory(history_id::Int)
    renderhforest(BitemporalPostgres.Node(Nothing,
            mkforest(
                DbId(history_id),
                MaxDate,
                ZonedDateTime(1900, 1, 1, 0, 0, 0, 0, tz"UTC"),
                MaxDate,
            )),
        0,
    )
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

end #module
