using Revise, JSON, BitemporalPostgres, LifeInsuranceDataModel, DataStructures, TimeZones, SearchLight
LifeInsuranceDataModel.connect()
current_workflow = find(Workflow, SQLWhereExpression("id=?", DbId(15)))[1]
ref_time = current_workflow.tsw_validfrom
cs::Dict{String,Any} = Dict()
cs_persisted::Dict{String,Any} = Dict()
CS_UNDO = Stack{Dict{String,Any}}()
cs_persisted = JSON.parse(JSON.json(csection(2, now(tz"UTC"), ref_time, 1)))
cs = deepcopy(cs_persisted)

push!(CS_UNDO, cs_persisted)

@show CS_UNDO
productpartnerroles::Dict{String,Integer} = Dict()
productpartnerroles["1"] = 1
new_product_reference = 2
#
#
#
prs0 = prsection(new_product_reference, now(tz"UTC"), ref_time)
@show prs0
productpartnerroles = Dict()

map(prs0.parts) do pt
    for r in pt.ref.partner_roles
        productpartnerroles[string(r.ref_role.value)] = 0
    end
end
productpartnerroles["1"] = 1
productpartnerroles["2"] = 2

@show productpartnerroles
@show values(productpartnerroles)
@show 0 in values(productpartnerroles)
partnerrolemap::Dict{Integer,PartnerSection} = Dict()
for keystr in keys(productpartnerroles)
    key = parse(Int, keystr)
    println
    partnerrolemap[key] = psection(productpartnerroles[keystr], now(tz"UTC"), ref_time)

end
@show partnerrolemap
@info "before instantiation"
pis = instantiate_product(prs0, partnerrolemap)
@info "productitem created"
pisj = JSON.parse(JSON.json(pis))
@show pisj
cs["product_items"] = [pisj]
@show cs["product_items"]
deltas = compareModelStateContract(cs_persisted, cs, current_workflow)
@show deltas