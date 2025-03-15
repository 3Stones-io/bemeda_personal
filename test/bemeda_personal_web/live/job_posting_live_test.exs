defmodule BemedaPersonalWeb.JobPostingLiveTest do
  use BemedaPersonalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  @create_attrs %{
    description: "some description",
    title: "some title",
    location: "some location",
    currency: "some currency",
    employment_type: "some employment_type",
    experience_level: "some experience_level",
    salary_min: 42,
    salary_max: 42,
    remote_allowed: true
  }
  @update_attrs %{
    description: "some updated description",
    title: "some updated title",
    location: "some updated location",
    currency: "some updated currency",
    employment_type: "some updated employment_type",
    experience_level: "some updated experience_level",
    salary_min: 43,
    salary_max: 43,
    remote_allowed: false
  }
  @invalid_attrs %{
    description: nil,
    title: nil,
    location: nil,
    currency: nil,
    employment_type: nil,
    experience_level: nil,
    salary_min: nil,
    salary_max: nil,
    remote_allowed: false
  }

  defp create_job_posting(_context) do
    user = user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(user)
    %{job_posting: job_posting, user: user, company: company}
  end

  describe "/job_postings" do
    setup [:create_job_posting]

    test "lists all job_postings", %{conn: conn, job_posting: job_posting} do
      {:ok, _index_live, html} = live(conn, ~p"/job_postings")

      assert html =~ "Listing Job postings"
      assert html =~ job_posting.description
    end

    test "saves new job_posting", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/job_postings")

      assert index_live
             |> element("a", "New Job posting")
             |> render_click() =~
               "New Job posting"

      assert_patch(index_live, ~p"/job_postings/new")

      assert index_live
             |> form("#job_posting-form", job_posting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#job_posting-form", job_posting: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/job_postings")

      html = render(index_live)
      assert html =~ "Job posting created successfully"
      assert html =~ "some description"
    end

    test "updates job_posting in listing", %{conn: conn, job_posting: job_posting} do
      {:ok, index_live, _html} = live(conn, ~p"/job_postings")

      assert index_live
             |> element("#job_postings-#{job_posting.id} a", "Edit")
             |> render_click() =~
               "Edit Job posting"

      assert_patch(index_live, ~p"/job_postings/#{job_posting}/edit")

      assert index_live
             |> form("#job_posting-form", job_posting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#job_posting-form", job_posting: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/job_postings")

      html = render(index_live)
      assert html =~ "Job posting updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes job_posting in listing", %{conn: conn, job_posting: job_posting} do
      {:ok, index_live, _html} = live(conn, ~p"/job_postings")

      assert index_live
             |> element("#job_postings-#{job_posting.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#job_postings-#{job_posting.id}")
    end
  end

  describe "/job_postings/:id" do
    setup [:create_job_posting]

    test "displays job_posting", %{conn: conn, job_posting: job_posting} do
      {:ok, _show_live, html} = live(conn, ~p"/job_postings/#{job_posting}")

      assert html =~ "Show Job posting"
      assert html =~ job_posting.description
    end

    test "updates job_posting within modal", %{conn: conn, job_posting: job_posting} do
      {:ok, show_live, _html} = live(conn, ~p"/job_postings/#{job_posting}")

      assert show_live
             |> element("a", "Edit")
             |> render_click() =~
               "Edit Job posting"

      assert_patch(show_live, ~p"/job_postings/#{job_posting}/show/edit")

      assert show_live
             |> form("#job_posting-form", job_posting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#job_posting-form", job_posting: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/job_postings/#{job_posting}")

      html = render(show_live)
      assert html =~ "Job posting updated successfully"
      assert html =~ "some updated description"
    end
  end
end
