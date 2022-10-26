using LifeInsuranceDataModel, TimeZones
ENV["SEARCHLIGHT_USERNAME"] = "mf"
ENV["SEARCHLIGHT_PASSWORD"] = "mf"
csection(1, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"))
disconnect()