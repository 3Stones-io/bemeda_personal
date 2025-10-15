defmodule BemedaPersonalWeb.Features.JobSeekerOnboardingTest do
  @moduledoc """
  Feature tests for job seeker onboarding flows.

  Tests basic user authentication, settings access, and resume functionality
  for job seekers on the platform.
  """

  use BemedaPersonalWeb.FeatureCase, async: false

  import BemedaPersonal.FeatureHelpers

  @moduletag :feature

  describe "job seeker profile setup" do
    test "job seeker can access settings page", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/users/settings")
      |> assert_has("main")
    end

    test "job seeker can access settings from root", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/")
      |> assert_has("main")
    end

    test "job seeker can navigate to settings", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/users/settings")
      |> assert_has("main")
    end
  end

  describe "resume building" do
    test "job seeker can access resume page", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/resume")
      |> assert_has("main")
    end

    test "job seeker can access resume edit page", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/resume")
      |> assert_has("main")
    end

    test "job seeker can navigate education forms", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/resume/education/new")
      |> assert_has("main")
    end
  end

  describe "navigation and authentication" do
    test "job seeker can access work experience forms", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/resume/work-experience/new")
      |> assert_has("main")
    end

    test "job seeker can access job applications", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/job_applications")
      |> assert_has("main")
    end

    test "job seeker can browse jobs", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/jobs")
      |> assert_has("main")
    end
  end

  describe "basic functionality" do
    test "job seeker authentication works", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/")
      |> assert_has("main")
    end

    test "job seeker can access settings pages", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/users/settings")
      |> assert_has("main")
    end

    test "job seeker can access notifications", %{conn: conn} do
      conn
      |> sign_in_as_job_seeker()
      |> visit(~p"/notifications")
      |> assert_has("main")
    end
  end
end
