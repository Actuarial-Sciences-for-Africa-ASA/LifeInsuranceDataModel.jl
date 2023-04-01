using LifeInsuranceDataModel, TimeZones
ENV["SEARCHLIGHT_USERNAME"] = "mf"
ENV["SEARCHLIGHT_PASSWORD"] = "mf"
#csection(1, now(tz"UTC"), ZonedDateTime(2022, 11, 01, 12, 0, 1, 1, tz"UTC"))
LifeInsuranceDataModel.connect()

tariffparameters = """
{"n": {"type": "Int", "default": 0,"value":null},
 "m": {"type": "Int", "default": 0,"value":null},
 "begin": {"type": "Date", "default": "2020-01-01","value":null}
}
  """
contract_attributes = """
{"n": {"type": "Int", "default": 0,"value":null},
 "m": {"type": "Int", "default": 0,"value":null},
 "begin": {"type": "Date", "default": "2020-01-01","value":null}
}
  """
LifeRiskTariff = create_tariff("Life Risk Insurance", 1, 0.02, "1980 CET - Male Nonsmoker, ANB", tariffparameters, contract_attributes)