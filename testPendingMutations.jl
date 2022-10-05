push!(LOAD_PATH, "src")
using BitemporalPostgres, JSON, LifeInsuranceDataModel, SearchLight, Test, TimeZones, ToStruct
ENV["SEARCHLIGHT_USERNAME"] = "bitemporalpostgres"
ENV["SEARCHLIGHT_PASSWORD"] = "jw8s0F49KL"

LifeInsuranceDataModel.connect()

c = find(Contract)[1]
h = c.ref_history
w = Workflow(type_of_entity="Contract",
    ref_history=h,
    tsw_validfrom=ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"),
)
update_entity!(w)

committed = csection(c.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"))
changed = csection(c.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"))

changed.revision.description = "CR first mutation by GUI model"
changed.partner_refs[1].rev.description = "CPR first mutation by GUI model"
changed.product_items[1].revision.description = "PIR first mutation by GUI model"
changed.product_items[1].tariff_items[1].tariff_ref.rev.deferment = 9
changed.product_items[1].tariff_items[1].tariff_ref.rev.description = "TIR first mutation by GUI model"
changed.product_items[1].tariff_items[1].partner_refs[1].rev.description = "bubu|"

deltas = [
    (committed.revision, changed.revision)
    (committed.partner_refs[1].rev, changed.partner_refs[1].rev)
    (committed.product_items[1].revision, changed.product_items[1].revision)
    (committed.product_items[1].tariff_items[1].tariff_ref.rev, changed.product_items[1].tariff_items[1].tariff_ref.rev)
    (committed.product_items[1].tariff_items[1].partner_refs[1].rev, changed.product_items[1].tariff_items[1].partner_refs[1].rev)]

for delta in deltas
    println(delta)
    prev = delta[1]
    curr = delta[2]
    update_component!(prev, curr, w)
end

persisted = csection(c.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"), 1)

@testset "persisted pending transactions" begin
    @test(persisted.revision.description == changed.revision.description)
    @test(persisted.partner_refs[1].rev.description == changed.partner_refs[1].rev.description)
    @test(persisted.product_items[1].revision.description == changed.product_items[1].revision.description)
    @test(persisted.product_items[1].tariff_items[1].tariff_ref.rev.deferment == changed.product_items[1].tariff_items[1].tariff_ref.rev.deferment)
    @test(persisted.product_items[1].tariff_items[1].tariff_ref.rev.description == changed.product_items[1].tariff_items[1].tariff_ref.rev.description)
    @test(persisted.product_items[1].tariff_items[1].partner_refs[1].rev.description == changed.product_items[1].tariff_items[1].partner_refs[1].rev.description)
end

rollback_workflow!(w)
rolledback = csection(c.id.value, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"), 0)

@testset "rolled back pending transactions" begin
    @test(rolledback.revision.description == committed.revision.description)
    @test(rolledback.partner_refs[1].rev.description == committed.partner_refs[1].rev.description)
    @test(rolledback.product_items[1].revision.description == committed.product_items[1].revision.description)
    @test(rolledback.product_items[1].tariff_items[1].tariff_ref.rev.deferment == committed.product_items[1].tariff_items[1].tariff_ref.rev.deferment)
    @test(rolledback.product_items[1].tariff_items[1].tariff_ref.rev.description == committed.product_items[1].tariff_items[1].tariff_ref.rev.description)
    @test(rolledback.product_items[1].tariff_items[1].partner_refs[1].rev.description == committed.product_items[1].tariff_items[1].partner_refs[1].rev.description)
end