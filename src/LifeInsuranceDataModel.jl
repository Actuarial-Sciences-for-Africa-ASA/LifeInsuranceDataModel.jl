module LifeInsuranceDataModel

import Base: @kwdef
using JSON
using Logging
using SearchLight
using TimeZones
using ToStruct
using BitemporalPostgres
include("DDL.jl")
using .DDL
include("InsuranceContracts.jl")
using .InsuranceContracts
export persistModelStateContract,
    compareRevisions,
    Contract,
    ContractRevision,
    ContractPartnerRole,
    ContractPartnerRef,
    ContractPartnerReference,
    ContractPartnerRefRevision,
    csection,
    connect,
    disconnect, get_typeof_component, get_typeof_revision,
    get_contracts,
    get_partners,
    get_products,
    history_forest,
    instantiate_product,
    load_role,
    load_roles,
    psection,
    ProductItem,
    ProductItemRevision,
    ProductItemProductReference,
    TariffItemRole,
    TariffItem,
    TariffItemRevision,
    TariffItemPartnerRole,
    TariffItemPartnerRef,
    TariffItemPartnerReference,
    TariffItemPartnerRefRevision,
    TariffItemTariffReference,
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

export Product, ProductRevision, ProductPart, ProductPartRevision, ProductPartRole, Tariff, TariffRevision, TariffPartnerRole, TariffPartnerRoleRevision,
    create_tariff
export ContractSection, ProductItemSection, PartnerSection, TariffItemSection, TariffSection, csection, pisection, tsection, psection, load_model
export ProductSection, ProductPartSection, prsection
export ProductInterface, TariffInterface, get_product_interface, get_tariff_interface, validate

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
    partner_roles::Vector{TariffPartnerRoleRevision} = []
    contract_attributes::Dict{String,Any} = Dict()
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
ProductItemProductReference is a reference from a ProductItem to a product entity
"""
@kwdef mutable struct ProductItemProductReference
    rev::ProductItemRevision = ProductItemRevision()
    ref::ProductSection = ProductSection()
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
    partner_refs::Vector{TariffItemPartnerReference} = []
    contract_attributes::Dict{String,Any} = Dict()
end

"""
ProductItemSection is a section (see above) of a ProductItem component
"""
@kwdef mutable struct ProductItemSection
    product_ref::ProductSection = ProductSection()
    revision::ProductItemRevision = ProductItemRevision()
    tariff_items::Vector{TariffItemSection} = []
end

"""
ContractPartnerReference
	holds attributes of the reference from contract and a partner section
"""
@kwdef mutable struct ContractPartnerReference
    rev::ContractPartnerRefRevision = ContractPartnerRefRevision()
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
    partner_refs::Vector{ContractPartnerReference} = []
    product_items::Vector{ProductItemSection} = []
end

"""
mutable struct TariffInterface
"""
mutable struct TariffInterface
    description::String
    calls::Dict{String,Any}
    calculator::Function
    validator::Function
    parameters::Dict{String,Any}
    contract_attributes::Dict{String,Any}
    partnerroles::Vector{Int}
end


function get_tariff_interface(interface_id::Integer)::TariffInterface
    get_tariff_interface(Val(interface_id))
end

function get_tariff_interface(::Val{T})::TariffInterface where {T<:Integer}
end

function get_tariff_interface(tis::TariffItemSection)::TariffInterface
    get_tariff_interface(tis.tariff_ref.ref.revision.interface_id)
end

function LifeInsuranceDataModel.get_tariff_interface(::Val{0})
    TariffInterface("Dummy", Dict{String, Any}(), identity, identity, Dict{String, Any}(), Dict{String, Any}(), Int64[])
end

"""
mutable struct ProductInterface
"""

mutable struct ProductInterface
    description::String
    calls::Dict{String,Any}
    calculator::Function
    validator::Function
    parameters::Dict{String,Any}
    contract_attributes::Dict{String,Any}
    tariffs::Vector{TariffInterface}
end

function get_product_interface(interface_id::Integer)::ProductInterface
    get_product_interface(Val(interface_id))
end

function get_product_interface(::Val{T})::ProductInterface where {T<:Integer}
end

function get_product_interface(pis::ProductItemSection)::ProductInterface
    get_product_interface(pis.product_ref.revision.interface_id)
end

function validate(pis::ProductItemSection)
    get_product_interface(pis).validator(pis)
    map(pis.tariff_items) do tis
        get_tariff_interface(tis).validator(tis)
    end
end

"""
create_product_instance(wf::Workflow; pi::ProductItem, p::Integer, partnerrolemap::Dict{Integer,PartnerSection})

	creates tariff items of a productitem pi corresponding to
	the product parts of a Product p referencing the respective tariffs
	and Partner refp1 in role prole1
    expects a persisted productitem 
    yields persisted tariff itemscalculate!
"""

function create_product_instance(wf::Workflow, pi::ProductItem, p::Integer, partnerrolemap::Dict{Integer,PartnerSection})
    map(find(ProductPart, SQLWhereExpression("ref_super=?", p))) do pp
        println(pp.id.value)
        map(find(ProductPartRevision, SQLWhereExpression("ref_component=?", pp.id.value))) do ppr
            println(ppr.description)
            tr = find(TariffRevision, SQLWhereExpression("ref_component=?", ppr.ref_tariff))[1]
            ti = TariffItem(ref_super=pi.id)
            tir = TariffItemRevision(ref_role=ppr.ref_role, ref_tariff=ppr.ref_tariff, description=ppr.description, contract_attributes=tr.contract_attributes)
            create_subcomponent!(pi, ti, tir, wf)
            for role in keys(partnerrolemap)
                tip = TariffItemPartnerRef(ref_super=ti.id)
                tipr = TariffItemPartnerRefRevision(ref_partner=partnerrolemap[role].revision.id, ref_role=role)
                create_subcomponent!(ti, tip, tipr, wf)
                println(tipr)
            end
        end
    end
end

"""
function pisection(history_id::Integer, version_id::Integer, tsdb_validfrom, tsworld_validfrom)::Vector{ProductItemSection}

	pisection retrieves the vector of a contract's productitem sections
"""
function pisection(history_id::Integer, version_id::Integer, tsdb_validfrom, tsworld_validfrom)::Vector{ProductItemSection}
    pis = find(ProductItem, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
    collect(
        Iterators.flatten(
            map(pis) do pi
                map(get_revisionIfAny(ProductItemRevision, pi.id, DbId(version_id))) do pir
                    let trs = find(TariffItem, SQLWhereExpression("ref_history = BIGINT ? and ref_super = BIGINT ? ", DbId(history_id), pi.id)),
                        pitrs = map(trs) do tr
                            let trr = get_revision(TariffItemRevision, tr.id, DbId(version_id)),
                                ts = tsection(trr.ref_tariff.value, tsdb_validfrom, tsworld_validfrom),
                                pitrprs = find(TariffItemPartnerRef, SQLWhereExpression("ref_history = BIGINT ? and ref_super = BIGINT ? ", DbId(history_id), tr.id)),
                                pitrprrs = collect(Iterators.flatten(map(pitrprs) do pr
                                    map(get_revisionIfAny(TariffItemPartnerRefRevision, pr.id, DbId(version_id))) do prr
                                        let ps = psection(prr.ref_partner.value, tsdb_validfrom, tsworld_validfrom)
                                            TariffItemPartnerReference(prr, ps)
                                        end
                                    end
                                end))

                                ca = JSON.parse(trr.contract_attributes)
                                TariffItemSection(tariff_ref=TariffItemTariffReference(trr, ts), partner_refs=pitrprrs, contract_attributes=ca)
                            end
                        end

                        prs = prsection(pir.ref_product.value, tsdb_validfrom, tsworld_validfrom, 0)
                        ProductItemSection(revision=pir, tariff_items=pitrs, product_ref=prs)
                    end
                end
            end,
        ),
    )
end

"""
csection(contract_id::Integer, tsdb_validfrom, tsworld_validfrom,activeTransaction::Integer=0)::ContractSectio

	csection retrieves the section of a contract or throws NoVersionFound 
"""
function csection(contract_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::ContractSection
    connect()
    history_id = find(Contract, SQLWhereExpression("id=?", DbId(contract_id)))[1].ref_history.value
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom, activeTransaction == 1 ? 0 : 1).value
    let cr = get_revision(Contract, ContractRevision, DbId(history_id), DbId(version_id))
        ContractSection(
            ref_history=DbId(history_id),
            ref_version=DbId(version_id),
            revision=cr,
            partner_refs=let cprs = find(ContractPartnerRef, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
                collect(Iterators.flatten(map(cprs) do cpr
                    map(get_revisionIfAny(ContractPartnerRefRevision, cpr.id, DbId(version_id))) do cprr
                        let ps = psection(cprr.ref_partner.value, tsdb_validfrom, tsworld_validfrom)

                            ContractPartnerReference(cprr, ps)
                        end
                    end
                end))
            end,
            product_items=pisection(history_id, version_id, tsdb_validfrom, tsworld_validfrom),
        )
    end
end

"""
psection(partner_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::PartnerSection

	psection retrieves a section of a partner  or throws NoVersionFound

"""
function psection(partner_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::PartnerSection
    connect()
    history_id = find(Partner, SQLWhereExpression("id=?", DbId(partner_id)))[1].ref_history
    version_id = findversion(history_id, tsdb_validfrom, tsworld_validfrom, activeTransaction == 1 ? 0 : 1).value
    let pr = get_revision(Partner, PartnerRevision, DbId(history_id), DbId(version_id))
        PartnerSection(revision=pr)
    end
end

"""
tsection(tariff_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::TariffSection

	tsection retrieves a section of a tariff or throws NoVersionFound

"""
function tsection(tariff_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::TariffSection
    connect()
    history_id = find(Tariff, SQLWhereExpression("id=?", DbId(tariff_id)))[1].ref_history
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom, activeTransaction == 1 ? 0 : 1).value
    let tr = get_revision(Tariff, TariffRevision, DbId(history_id), DbId(version_id))
        trpr = collect(Iterators.flatten(map(find(TariffPartnerRole, SQLWhereExpression("ref_super=?", tr.ref_component))) do tpr
            get_revisionIfAny(TariffPartnerRoleRevision, DbId(tpr.id), DbId(version_id))
        end))
        try
            ca = JSON.parse(tr.contract_attributes)
            TariffSection(revision=tr, partner_roles=trpr, contract_attributes=ca)
        catch err
            @error ("ERROR:  exception parsing contract attributes " * tr.contract_attributes * "  tariff=" * tr.ref_component)
        end

    end
end

"""
prsection(product_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::ProductSection

	prsection retrieves a section of a product or throws NoVersionFound

"""
function prsection(product_id::Integer, tsdb_validfrom, tsworld_validfrom, activeTransaction::Integer=0)::ProductSection
    connect()
    history_id = find(Product, SQLWhereExpression("id=?", DbId(product_id)))[1].ref_history
    version_id = findversion(DbId(history_id), tsdb_validfrom, tsworld_validfrom, activeTransaction == 1 ? 0 : 1).value
    let pr = get_revision(Product, ProductRevision, DbId(history_id), DbId(version_id))
        ProductSection(revision=pr, parts=let pts = find(ProductPart, SQLWhereExpression("ref_history = BIGINT ? ", DbId(history_id)))
            collect(Iterators.flatten(map(pts) do pt
                map(get_revisionIfAny(ProductPartRevision, pt.id, DbId(version_id))) do ptr
                    let ref = tsection(ptr.ref_tariff.value, tsdb_validfrom, tsworld_validfrom)

                        ProductPartSection(ptr, ref)
                    end
                end
            end))
        end)
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
get_partners
	get_partners retrieves all partner entities - search capabilities to be added 
"""
function get_partners()
    connect()
    find(Partner)
end


"""
get_products
	get_products retrieves all product entities - search capabilities to be added 
"""
function get_products()
    connect()
    find(Product)
end

"""
create_tariff(dsc::String, interface::Integer, parameters::String, contract_attributes::String, tariffpartnerroles::Vector{Int}=[1])

  create a tariff, default partnerroles :[1]
"""

function create_tariff(dsc::String, interface::Integer, parameters::String, contract_attributes::String, tariffpartnerroles::Vector{Int}=[1])

    t = LifeInsuranceDataModel.Tariff()
    tr = LifeInsuranceDataModel.TariffRevision(description=dsc, interface_id=interface, parameters=parameters, contract_attributes=contract_attributes)
    w = Workflow(
        type_of_entity="Tariff",
        tsw_validfrom=ZonedDateTime(2014, 5, 30, 21, 0, 1, 1, tz"UTC"),
    )
    create_entity!(w)
    create_component!(t, tr, w)
    for role in tariffpartnerroles
        let
            tpr = LifeInsuranceDataModel.TariffPartnerRole()
            tprr = LifeInsuranceDataModel.TariffPartnerRoleRevision(ref_role=role)
            create_subcomponent!(t, tpr, tprr, w)
        end
    end
    commit_workflow!(w)
    t.id.value
end


"""
MVVM functions, creation of product items, comparison and persisting of model states
"""

"""
instantiate_product(prs::ProductSection, prrolemap::Dict{Integer,Integer})::ProductItemSection

  derive a product item from a product id and a map from role ids to partner ids
  interpreting product data 
  yields a transient ProductItemSection

"""

function instantiate_product(prs::ProductSection, partnerrolemap::Dict{Integer,PartnerSection})
    ts = map(prs.parts) do pt
        let tiprs = map(pt.ref.partner_roles) do r
                TariffItemPartnerReference(rev=TariffItemPartnerRefRevision(ref_role=r.ref_role.value, ref_partner=partnerrolemap[r.ref_role.value].revision.id))
            end
            tir = TariffItemRevision(ref_role=pt.revision.ref_role, ref_tariff=pt.revision.ref_tariff, contract_attributes=pt.ref.revision.contract_attributes)
            titr = TariffItemTariffReference(ref=pt.ref, rev=tir)
            ca = JSON.parse(tir.contract_attributes)
            TariffItemSection(tariff_ref=titr, partner_refs=tiprs, contract_attributes=ca)
        end
    end
    pir = ProductItemRevision(ref_product=prs.revision.ref_component)
    ProductItemSection(revision=pir, tariff_items=ts)
end
"""
compareRevisions(t, previous::Dict{String,Any}, current::Dict{String,Any}) where {T<:BitemporalPostgres.ComponentRevision}
compare corresponding revision elements and return nothing if equal a pair of both else
"""
function compareRevisions(t, previous::Dict{String,Any}, current::Dict{String,Any})
    let changed = false
        for (key, previous_value) in previous
            if !(key in ("ref_validfrom", "ref_invalidfrom", "ref_component"))
                let current_value = current[key]
                    if previous_value != current_value
                        changed = true
                    end
                end
            end
        end
        if (changed)
            (ToStruct.tostruct(t, previous), ToStruct.tostruct(t, current))
        end
    end
end

"""
persistModelStateContract(previous::Dict{String,Any}, current::Dict{String,Any}, w::Workflow, component::Component)
	persist the delta between previous and current state into into the workflow context
"""
function persistModelStateContract(previous::Dict{String,Any}, current::Dict{String,Any}, w::Workflow, rootcomponent::Component)
    @show current["revision"]
    @show previous
    cr = compareRevisions(ContractRevision, previous["revision"], current["revision"])
    if (!isnothing(cr))
        update_component!(ToStruct.tostruct(ContractRevision, previous["revision"]), ToStruct.tostruct(ContractRevision, current["revision"]), w)
    end
    @info "comparing Partner_refs"
    for i in 1:length(current["partner_refs"])
        @show current["partner_refs"]
        let
            curr = current["partner_refs"][i]["rev"]

            @info "current pref rev"
            @show curr
            if isnothing(curr["id"]["value"])
                @info ("INSERT" * string(i))
                let
                    component = rootcomponent
                    curr_struct = ToStruct.tostruct(ContractPartnerRefRevision, curr)
                    subcomponent = get_typeof_component(curr_struct)()
                    create_subcomponent!(component, subcomponent, curr_struct, w)
                end
            else
                let
                    prev = previous["partner_refs"][i]["rev"]
                    if curr["ref_invalidfrom"]["value"] == w.ref_version
                        @info ("DELETE" * string(i))
                        delete_component!(ToStruct.tostruct(ContractPartnerRefRevision, curr), w)
                    else
                        @info ("UPDATE" * string(i))
                        cprr = compareRevisions(ContractPartnerRefRevision, prev, curr)
                        if (!isnothing(cprr))
                            update_component!(ToStruct.tostruct(ContractPartnerRefRevision, prev), ToStruct.tostruct(ContractPartnerRefRevision, curr), w)
                        end
                    end
                end
            end
        end
    end
    # TODO fortsetzen refactoring direkt persistieren statt diff list
    # curr component subcomponents müssen let variablen sein
    @info "comparing product items"
    for i in 1:length(current["product_items"])
        @show current["product_items"]
        let
            curr = current["product_items"][i]["revision"]
            @info "current pref rev"
            @show curr
            if isnothing(curr["id"]["value"]) || curr["ref_invalidfrom"]["value"] == w.ref_version
                let
                    picomponent = rootcomponent
                    pisubcomponent = get_typeof_component(ToStruct.tostruct(ProductItemRevision, curr))()
                    @info ("INSERT/DELETE productitem" * string(i) * "c=" * string(picomponent.id.value))
                    create_subcomponent!(picomponent, pisubcomponent, ToStruct.tostruct(ProductItemRevision, curr), w)
                    for j in 1:length(current["product_items"][i]["tariff_items"])
                        let
                            curr = current["product_items"][i]["tariff_items"][j]["tariff_ref"]["rev"]
                            curr["contract_attributes"] = JSON.json(current["product_items"][i]["tariff_items"][j]["contract_attributes"])
                            ticomponent = pisubcomponent
                            tisubcomponent = get_typeof_component(ToStruct.tostruct(TariffItemRevision, curr))()
                            @info ("INSERT/DELETE tariff item " * string(i) * "/" * string(j) * "c=" * string(ticomponent.id.value))
                            create_subcomponent!(ticomponent, tisubcomponent, ToStruct.tostruct(TariffItemRevision, curr), w)
                            for k in 1:length(current["product_items"][i]["tariff_items"][j]["partner_refs"])
                                let
                                    curr = current["product_items"][i]["tariff_items"][j]["partner_refs"][k]["rev"]
                                    tiprcomponent = tisubcomponent
                                    tiprsubcomponent = get_typeof_component(ToStruct.tostruct(TariffItemPartnerRefRevision, curr))()
                                    @info ("INSERT/DELETE tariffitempartners" * string(i) * "/" * string(j) * "/" * string(k) * "c=" * string(tiprcomponent.id.value))
                                    create_subcomponent!(tiprcomponent, tiprsubcomponent, ToStruct.tostruct(TariffItemPartnerRefRevision, curr), w)
                                end
                            end
                        end
                    end
                end
            else
                prev = previous["product_items"][i]["revision"]
                @info ("UPDATE productitem" * string(i))
                pirr = compareRevisions(ProductItemRevision, prev, curr)
                if !isnothing(pirr)
                    if (!isnothing(pirr))
                        update_component!(ToStruct.tostruct(ProductItemRevision, prev), ToStruct.tostruct(ProductItemRevision, curr), w)
                    end
                end
                @info "UPDATE tariff items"

                for j in 1:length(current["product_items"][i]["tariff_items"])
                    let
                        curr = current["product_items"][i]["tariff_items"][j]["tariff_ref"]["rev"]
                        curr["contract_attributes"] = JSON.json(current["product_items"][i]["tariff_items"][j]["contract_attributes"])
                        prev = previous["product_items"][i]["tariff_items"][j]["tariff_ref"]["rev"]
                        tirr = compareRevisions(TariffItemRevision, prev, curr)
                        if !isnothing(tirr)
                            update_component!(ToStruct.tostruct(TariffItemRevision, prev), ToStruct.tostruct(TariffItemRevision, curr), w)
                        end
                        @info "INSERT/DELETE tariffitempartners"
                        for k in 1:length(current["product_items"][i]["tariff_items"][j]["partner_refs"])
                            let
                                curr = current["product_items"][i]["tariff_items"][j]["partner_refs"][k]["rev"]
                                prev = previous["product_items"][i]["tariff_items"][j]["partner_refs"][k]["rev"]
                                tiprr = compareRevisions(TariffItemPartnerRefRevision, prev, curr)
                                if !isnothing(tiprr)
                                    update_component!(ToStruct.tostruct(TariffItemPartnerRefRevision, prev), ToStruct.tostruct(TariffItemPartnerRefRevision, curr), w)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
"""
utilities: loading roles, managing aconnections
"""

"""
connect0
internal function for DB connect
"""
function connect0()
    let conf = SearchLight.Configuration.load()
        setfield!(SearchLight.config, :log_queries, true)
        setfield!(SearchLight.config, :log_level, Logging.Error)
        SearchLight.connect(conf)
    end
end

"""
connect
	database connect as configured 
"""
function connect()

    try
        let conn = SearchLight.connection()
            if (isopen(conn))
                @info("already connected")
            else
                connect0()
            end
        end
    catch ex
        connect0()
    end
end

"""
disconnect
	disconnect from database
"""
function disconnect()
    try
        let conn = SearchLight.connection()
            if (isopen(conn))
                close(conn)
            end
        end
    catch ex
        Nothing
    end
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
function load_role(role)::Vector{Dict{String,Any}}
    into ViewModel
"""

function load_role(role)::Vector{Dict{String,Any}}
    LifeInsuranceDataModel.connect()
    map(find(role)) do entry
        Dict{String,Any}("value" => entry.id.value, "label" => entry.value)
    end
end

"""
load_model
	create the DDL of the model
"""

function load_model()
    connect()
    SearchLight.Migrations.create_migrations_table()
    DDL.up()
    load_roles()
end

end #module
