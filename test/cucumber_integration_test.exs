defmodule BemedaPersonal.CucumberIntegrationTest do
  @moduledoc """
  Verifies Cucumber is properly configured and integrated.
  """

  use ExUnit.Case, async: true

  test "Cucumber dependency is available" do
    assert Code.ensure_loaded?(Cucumber)
    assert Code.ensure_loaded?(Cucumber.StepDefinition)
  end

  test "feature files directory exists" do
    assert File.dir?("test/features")
    assert File.dir?("test/features/step_definitions")
  end

  test "step definition files exist" do
    assert File.exists?("test/features/step_definitions/common_steps.exs")
    assert File.exists?("test/features/step_definitions/job_steps.exs")
  end

  test "example feature file exists" do
    assert File.exists?("test/features/job_seeker/job_application.feature")
  end
end
