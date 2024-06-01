push!(LOAD_PATH, "src")
using BitemporalPostgres, JSON, LifeInsuranceDataModel, SearchLight, Test, TimeZones, ToStruct

LifeInsuranceDataModel.connect()

current_contract = find(Contract)[1]
h = current_contract.ref_history
current_workflow = Workflow(type_of_entity="Contract",
    ref_history=h,
    tsw_validfrom=ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"),
)
update_entity!(current_workflow)

committed = JSON.parse(JSON.json(csection(current_contract.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"))))
changed = JSON.parse(JSON.json(csection(current_contract.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"))))
changed["revision"]["description"] = "CR first mutation by GUI model"
changed["partner_refs"][1]["rev"]["description"] = "CPR first mutation by GUI model"
changed["product_items"][1]["revision"]["description"] = "PIR first mutation by GUI model"
changed["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] = 9
changed["product_items"][1]["tariff_items"][1]["tariff_ref"]["rev"]["description"] = "TIR first mutation by GUI model"
changed["product_items"][1]["tariff_items"][1]["partner_refs"][1]["rev"]["description"] = "bubu|"

persistModelStateContract(committed, changed, current_workflow, current_contract)

persisted = JSON.parse(JSON.json(csection(current_contract.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"), 1)))

@testset "persisted pending transactions" begin
    @test(persisted["revision"]["description"] == changed["revision"]["description"])
    @test(persisted["partner_refs"][1]["rev"]["description"] == changed["partner_refs"][1]["rev"]["description"])
    @test(persisted["product_items"][1]["revision"]["description"] == changed["product_items"][1]["revision"]["description"])
    @test(persisted["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] == changed["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"])
    @test(persisted["product_items"][1]["tariff_items"][1]["tariff_ref"]["rev"]["description"] == changed["product_items"][1]["tariff_items"][1]["tariff_ref"]["rev"]["description"])
    @test(persisted["product_items"][1]["tariff_items"][1]["partner_refs"][1]["rev"]["description"] == changed["product_items"][1]["tariff_items"][1]["partner_refs"][1]["rev"]["description"])
end

rollback_workflow!(current_workflow)
rolledback = JSON.parse(JSON.json(csection(current_contract.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"), 0)))

@testset "rolled back pending transactions" begin
    @test(rolledback["revision"]["description"] == committed["revision"]["description"])
    @test(rolledback["partner_refs"][1]["rev"]["description"] == committed["partner_refs"][1]["rev"]["description"])
    @test(rolledback["product_items"][1]["revision"]["description"] == committed["product_items"][1]["revision"]["description"])
    @test(rolledback["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"] == committed["product_items"][1]["tariff_items"][1]["contract_attributes"]["n"]["value"])
    @test(rolledback["product_items"][1]["tariff_items"][1]["tariff_ref"]["rev"]["description"] == committed["product_items"][1]["tariff_items"][1]["tariff_ref"]["rev"]["description"])
    @test(rolledback["product_items"][1]["tariff_items"][1]["partner_refs"][1]["rev"]["description"] == committed["product_items"][1]["tariff_items"][1]["partner_refs"][1]["rev"]["description"])
end