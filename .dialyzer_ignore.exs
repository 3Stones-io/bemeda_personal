[
  # PhoenixTest.Playwright function warnings
  ~r/Function PhoenixTest\.Playwright\.Case\.__using__\/1 has no local return/,
  ~r/The call PhoenixTest\.Playwright\..*\(.*\) might fail due to a possible race condition/,

  # PhoenixTest functions used in feature_helpers.ex
  ~r/test\/support\/feature_helpers\.ex.*Function PhoenixTest\./
]
