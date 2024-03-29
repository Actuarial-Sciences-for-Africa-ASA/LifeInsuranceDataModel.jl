using Revise, Test, JSON, BitemporalPostgres, LifeInsuranceDataModel, DataStructures, TimeZones, SearchLight
LifeInsuranceDataModel.connect()
current_workflow = Workflow(
    type_of_entity="Contract",
    tsw_validfrom=ZonedDateTime(Date("2023-03-01"), tz"UTC"),
    tsdb_validfrom=now(tz"UTC")
)
create_entity!(current_workflow)
c = Contract()
cr = ContractRevision(description="contract creation properties")
@info "before create component"
create_component!(c, cr, current_workflow)

current_contract = c

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
cs["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] = 99
persistModelStateContract(cs_persisted, cs, current_workflow, current_contract)

@testset "load contract uncommitted" begin
    cs::ContractSection = csection(current_contract.id.value, now(tz"UTC"), ZonedDateTime(Date("2023-03-01"), tz"UTC"), 1)
    @test cs.product_items[1].tariff_items[1].partner_refs[1].rev.ref_partner.value == 1
end

@testset "load contract committed" begin
    commit_workflow!(current_workflow)
    cs::ContractSection = csection(current_contract.id.value, now(tz"UTC"), ZonedDateTime(Date("2023-03-01"), tz"UTC"), 0)
    @test cs.product_items[1].tariff_items[1].partner_refs[1].rev.ref_partner.value == 1
    @test cs.product_items[1].tariff_items[1].contract_attributes["n"]["value"] == 99
end




@testset "load contract committed 2 " begin
    current_workflow = Workflow(
        type_of_entity="Contract",
        tsw_validfrom=ZonedDateTime(Date("2023-04-01"), tz"UTC"),
        tsdb_validfrom=now(tz"UTC"),
        ref_history=c.ref_history
    )

    update_entity!(current_workflow)
    cs = JSON.parse(JSON.json(csection(current_contract.id.value, current_workflow.tsdb_validfrom, current_workflow.tsw_validfrom, 1)))
    cs_persisted = deepcopy(cs)
    @test cs["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] == 99

    cs["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] = 88
    persistModelStateContract(cs_persisted, cs, current_workflow, current_contract)
    @test cs["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] == 88
    commit_workflow!(current_workflow)
    cs = JSON.parse(JSON.json(csection(current_contract.id.value, current_workflow.tsdb_validfrom, current_workflow.tsw_validfrom, 0)))
    @test cs["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] == 88
end




