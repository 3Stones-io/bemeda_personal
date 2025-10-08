defmodule BemedaPersonal.JobApplicationsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Chat
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobApplications.JobApplicationStateTransition
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  defp create_job_posting(_attrs) do
    user = employer_user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(user, job_posting)

    %{
      company: company,
      job_posting: job_posting,
      user: user,
      job_application: job_application
    }
  end

  describe "create_job_application/3" do
    test "creates a job_application with valid data" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting =
        company
        |> job_posting_fixture()
        |> Repo.preload(:company)

      valid_attrs = %{
        "cover_letter" => "some cover letter",
        "media_data" => %{
          "file_name" => "app_file.mp4",
          "status" => "uploaded",
          "type" => "video/mp4"
        }
      }

      assert {:ok, %JobApplication{} = job_application} =
               JobApplications.create_job_application(user, job_posting, valid_attrs)

      assert job_application.cover_letter == "some cover letter"
      assert job_application.job_posting_id == job_posting.id
      assert job_application.user_id == user.id
      assert job_application.media_asset
    end

    test "creates a job_application with nil media_data and no media asset" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting =
        company
        |> job_posting_fixture()
        |> Repo.preload(:company)

      valid_attrs = %{
        "cover_letter" => "some cover letter",
        "media_data" => nil
      }

      assert {:ok, %JobApplication{} = job_application} =
               JobApplications.create_job_application(user, job_posting, valid_attrs)

      assert job_application.cover_letter == "some cover letter"
      assert job_application.job_posting_id == job_posting.id
      assert job_application.user_id == user.id
      refute job_application.media_asset
    end

    test "creates a job_application with empty media_data and no media asset" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting =
        company
        |> job_posting_fixture()
        |> Repo.preload(:company)

      valid_attrs = %{
        "cover_letter" => "some cover letter",
        "media_data" => %{}
      }

      assert {:ok, %JobApplication{} = job_application} =
               JobApplications.create_job_application(user, job_posting, valid_attrs)

      assert job_application.cover_letter == "some cover letter"
      assert job_application.job_posting_id == job_posting.id
      assert job_application.user_id == user.id
      refute job_application.media_asset
    end

    test "creates a job_application with media asset" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting =
        company
        |> job_posting_fixture()
        |> Repo.preload(:company)

      valid_attrs = %{
        "cover_letter" => "some cover letter",
        "media_data" => %{
          "file_name" => "app_file.mp4",
          "status" => "uploaded",
          "type" => "video/mp4"
        }
      }

      assert {:ok, %JobApplication{} = job_application} =
               JobApplications.create_job_application(user, job_posting, valid_attrs)

      assert job_application.cover_letter == "some cover letter"
      assert job_application.job_posting_id == job_posting.id
      assert job_application.user_id == user.id
      assert job_application.media_asset
      assert job_application.media_asset.file_name == "app_file.mp4"
    end

    test "returns error changeset when data is invalid" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting =
        company
        |> job_posting_fixture()
        |> Repo.preload(:company)

      invalid_attrs = %{
        "cover_letter" => nil
      }

      assert {:error, %Ecto.Changeset{}} =
               JobApplications.create_job_application(user, job_posting, invalid_attrs)
    end

    test "broadcasts job_application_created event when creating a new job application" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting =
        company
        |> job_posting_fixture()
        |> Repo.preload(:company)

      company_job_application_topic = "job_application:company:#{job_posting.company_id}"
      user_job_application_topic = "job_application:user:#{user.id}"

      Endpoint.subscribe(company_job_application_topic)
      Endpoint.subscribe(user_job_application_topic)

      valid_attrs = %{
        "cover_letter" => "some cover letter",
        "media_data" => %{
          "file_name" => "app_file.mp4",
          "status" => "uploaded",
          "type" => "video/mp4"
        }
      }

      {:ok, job_application} =
        JobApplications.create_job_application(user, job_posting, valid_attrs)

      assert_receive %Broadcast{
        event: "company_job_application_created",
        topic: ^company_job_application_topic,
        payload: %{job_application: ^job_application}
      }

      assert_receive %Broadcast{
        event: "user_job_application_created",
        topic: ^user_job_application_topic,
        payload: %{job_application: ^job_application}
      }

      assert Ecto.assoc_loaded?(job_application.job_posting)
      assert Ecto.assoc_loaded?(job_application.user)
      assert Ecto.assoc_loaded?(job_application.media_asset)
      assert Ecto.assoc_loaded?(job_application.tags)
    end
  end

  describe "change_job_application/1" do
    setup [:create_job_posting]

    test "returns a job_posting changeset", %{job_application: job_application} do
      assert %Ecto.Changeset{} = JobApplications.change_job_application(job_application)
    end

    test "returns a job_posting changeset with errors when data is invalid", %{
      job_application: job_application
    } do
      changeset = JobApplications.change_job_application(job_application, %{cover_letter: nil})
      assert %Ecto.Changeset{valid?: false} = changeset
      assert errors_on(changeset)[:cover_letter] == ["can't be blank"]
    end
  end

  describe "update_job_application/2" do
    setup [:create_job_posting]

    test "updates the job_application with valid data", %{job_application: job_application} do
      update_attrs = %{
        "cover_letter" => "updated cover letter"
      }

      assert {:ok, %JobApplication{} = updated_job_application} =
               JobApplications.update_job_application(job_application, update_attrs)

      assert updated_job_application.cover_letter == "updated cover letter"
      assert updated_job_application.id == job_application.id
      assert updated_job_application.media_asset == job_application.media_asset
    end

    test "updates the job_application with nil media_data and doesn't create media asset",
         %{job_application: job_application} do
      update_attrs = %{
        "cover_letter" => "updated cover letter",
        "media_data" => nil
      }

      assert {:ok, %JobApplication{} = updated_job_application} =
               JobApplications.update_job_application(job_application, update_attrs)

      assert updated_job_application.cover_letter == "updated cover letter"
      assert updated_job_application.id == job_application.id
      refute updated_job_application.media_asset
    end

    test "updates the job_application with empty media_data and doesn't create media asset",
         %{job_application: job_application} do
      update_attrs = %{
        "cover_letter" => "updated cover letter",
        "media_data" => %{}
      }

      assert {:ok, %JobApplication{} = updated_job_application} =
               JobApplications.update_job_application(job_application, update_attrs)

      assert updated_job_application.cover_letter == "updated cover letter"
      assert updated_job_application.id == job_application.id
      refute updated_job_application.media_asset
    end

    test "updates the job_application with media asset", %{job_application: job_application} do
      update_attrs = %{
        "cover_letter" => "updated cover letter",
        "media_data" => %{
          "file_name" => "updated_file.mp4",
          "status" => "uploaded",
          "type" => "video/mp4"
        }
      }

      assert {:ok, %JobApplication{} = updated_job_application} =
               JobApplications.update_job_application(job_application, update_attrs)

      assert updated_job_application.cover_letter == "updated cover letter"
      assert updated_job_application.id == job_application.id
      assert updated_job_application.media_asset
      assert updated_job_application.media_asset.file_name == "updated_file.mp4"
    end

    test "returns error changeset with invalid data", %{job_application: job_application} do
      invalid_attrs = %{
        "cover_letter" => nil
      }

      assert {:error, %Ecto.Changeset{}} =
               JobApplications.update_job_application(job_application, invalid_attrs)

      unchanged_job_application = JobApplications.get_job_application_by_id!(job_application.id)
      assert unchanged_job_application.cover_letter == job_application.cover_letter
    end

    test "broadcasts job_application_updated event when updating a job application", %{
      job_application: job_application
    } do
      company_job_application_topic =
        "job_application:company:#{job_application.job_posting.company_id}"

      user_job_application_topic = "job_application:user:#{job_application.user_id}"

      Endpoint.subscribe(company_job_application_topic)
      Endpoint.subscribe(user_job_application_topic)

      update_attrs = %{
        "cover_letter" => "updated cover letter"
      }

      {:ok, updated_job_application} =
        JobApplications.update_job_application(job_application, update_attrs)

      assert_receive %Broadcast{
        event: "company_job_application_updated",
        topic: ^company_job_application_topic,
        payload: %{job_application: ^updated_job_application}
      }

      assert_receive %Broadcast{
        event: "user_job_application_updated",
        topic: ^user_job_application_topic,
        payload: %{job_application: ^updated_job_application}
      }
    end
  end

  describe "get_job_application!/1" do
    setup [:create_job_posting]

    test "returns the job_application with given id", %{job_application: job_application} do
      result = JobApplications.get_job_application_by_id!(job_application.id)
      assert result.id == job_application.id
      assert result.cover_letter == job_application.cover_letter
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
      assert Ecto.assoc_loaded?(result.media_asset)
    end

    test "returns the job_application with media asset" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      job_application = job_application_fixture(user, job_posting)

      media_data = %{
        "file_name" => "test_file.mp4",
        "status" => "uploaded",
        "type" => "video/mp4"
      }

      {:ok, _asset} =
        BemedaPersonal.Media.create_media_asset(job_application, media_data)

      result = JobApplications.get_job_application_by_id!(job_application.id)
      assert result.id == job_application.id
      assert result.media_asset
      assert result.media_asset.file_name == "test_file.mp4"
    end

    test "raises error when job application with id does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        JobApplications.get_job_application_by_id!(Ecto.UUID.generate())
      end
    end
  end

  describe "list_job_applications/2" do
    setup [:create_job_posting]

    test "returns all job applications when no filter is passed", %{
      job_application: job_application
    } do
      results = JobApplications.list_job_applications()
      assert length(results) >= 1

      # Find our specific job application in the results
      result = Enum.find(results, &(&1.id == job_application.id))
      assert result
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
      assert Ecto.assoc_loaded?(result.media_asset)
    end

    test "returns job applications with media assets" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      job_application = job_application_fixture(user, job_posting)

      # Create a media asset for the job application
      media_data = %{
        "file_name" => "list_file.mp4",
        "status" => "uploaded",
        "type" => "video/mp4"
      }

      {:ok, _asset} =
        BemedaPersonal.Media.create_media_asset(job_application, media_data)

      assert [result] = JobApplications.list_job_applications(%{job_posting_id: job_posting.id})
      assert result.id == job_application.id
      assert result.media_asset
      assert result.media_asset.file_name == "list_file.mp4"
    end

    test "can filter job applications by user_id", %{job_application: job_application, user: user} do
      user2 = user_fixture(%{email: "user2@example.com"})
      job_application_fixture(user2, job_application.job_posting)

      assert [result] = JobApplications.list_job_applications(%{user_id: user.id})
      assert result.id == job_application.id
      assert result.user_id == user.id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "can filter job applications by job_posting_id", %{
      job_application: job_application,
      user: user
    } do
      another_company = company_fixture(user)
      another_job_posting = job_posting_fixture(another_company)
      job_application_fixture(user, another_job_posting)

      assert [result] =
               JobApplications.list_job_applications(%{
                 job_posting_id: job_application.job_posting_id
               })

      assert result.id == job_application.id
      assert result.job_posting_id == job_application.job_posting_id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "can filter job applications by company_id", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      company_id = job_posting.company_id

      another_company = company_fixture(user)
      another_job_posting = job_posting_fixture(another_company)
      job_application_fixture(user, another_job_posting)

      results = JobApplications.list_job_applications(%{company_id: company_id})

      assert length(results) == 1
      [result] = results
      assert result.id == job_application.id
      assert result.job_posting.company_id == company_id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "returns empty list when a user has no job applications" do
      user = user_fixture(%{email: "no_applications@example.com"})
      non_existing_user_id = Ecto.UUID.generate()

      assert %{user_id: non_existing_user_id}
             |> JobApplications.list_job_applications()
             |> Enum.empty?()

      assert %{user_id: user.id}
             |> JobApplications.list_job_applications()
             |> Enum.empty?()
    end

    test "returns empty list when a job posting has no applications" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      non_existing_job_posting_id = Ecto.UUID.generate()

      assert %{job_posting_id: non_existing_job_posting_id}
             |> JobApplications.list_job_applications()
             |> Enum.empty?()

      assert %{job_posting_id: job_posting.id}
             |> JobApplications.list_job_applications()
             |> Enum.empty?()
    end

    test "can filter job applications by multiple parameters", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      user2 = user_fixture(%{email: "user2@example.com"})

      another_company = company_fixture(user)
      another_job_posting = job_posting_fixture(another_company)

      # Create job applications with different combinations
      job_application_fixture(user2, job_posting)
      job_application_fixture(user, another_job_posting)
      job_application_fixture(user2, another_job_posting)

      assert [result] =
               JobApplications.list_job_applications(%{
                 user_id: user.id,
                 job_posting_id: job_posting.id,
                 company_id: job_posting.company_id
               })

      assert result.id == job_application.id
      assert result.user_id == user.id
      assert result.job_posting_id == job_posting.id
    end

    test "defaults to listing all job applications if a non-existent filter is passed", %{
      job_application: job_application
    } do
      results = JobApplications.list_job_applications(%{unknown_filter: "unknown_filter"})
      assert length(results) >= 1

      # Find our specific job application in the results
      result = Enum.find(results, &(&1.id == job_application.id))
      assert result
      assert job_application.id == result.id
    end

    test "limits the number of returned job applications" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      Enum.each(1..15, fn _application ->
        job_application_fixture(user, job_posting, %{
          cover_letter: "Cover letter #{:rand.uniform(1000)}"
        })
      end)

      assert length(JobApplications.list_job_applications()) == 10
      assert length(JobApplications.list_job_applications(%{}, 5)) == 5
    end

    test "can filter job applications by newer_than and older_than timestamp" do
      # Use very old timestamps to avoid collisions with other async tests
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      older_timestamp = DateTime.from_naive!(~N[2020-01-01 00:00:00], "Etc/UTC")
      middle_timestamp = DateTime.from_naive!(~N[2020-02-01 00:00:00], "Etc/UTC")
      newer_timestamp = DateTime.from_naive!(~N[2020-03-01 00:00:00], "Etc/UTC")

      older_application =
        %JobApplication{}
        |> JobApplication.changeset(%{
          cover_letter: "Cover letter for older application"
        })
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:job_posting, job_posting)
        |> Ecto.Changeset.put_change(:inserted_at, older_timestamp)
        |> Repo.insert!()

      middle_application =
        %JobApplication{}
        |> JobApplication.changeset(%{
          cover_letter: "Cover letter for middle application"
        })
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:job_posting, job_posting)
        |> Ecto.Changeset.put_change(:inserted_at, middle_timestamp)
        |> Repo.insert!()

      newer_application =
        %JobApplication{}
        |> JobApplication.changeset(%{
          cover_letter: "Cover letter for newer application"
        })
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:job_posting, job_posting)
        |> Ecto.Changeset.put_change(:inserted_at, newer_timestamp)
        |> Repo.insert!()

      assert results =
               JobApplications.list_job_applications(%{
                 newer_than: middle_application,
                 user_id: user.id
               })

      assert length(results) == 1
      assert hd(results).id == newer_application.id

      assert results =
               JobApplications.list_job_applications(%{
                 older_than: middle_application,
                 user_id: user.id
               })

      assert length(results) == 1
      assert hd(results).id == older_application.id

      another_user = user_fixture(%{email: "another@example.com"})

      another_older_application =
        %JobApplication{}
        |> JobApplication.changeset(%{
          cover_letter: "Cover letter for another older application"
        })
        |> Ecto.Changeset.put_assoc(:user, another_user)
        |> Ecto.Changeset.put_assoc(:job_posting, job_posting)
        |> Ecto.Changeset.put_change(
          :inserted_at,
          DateTime.from_naive!(~N[2019-12-15 00:00:00], "Etc/UTC")
        )
        |> Repo.insert!()

      assert results =
               JobApplications.list_job_applications(%{
                 older_than: middle_application,
                 user_id: another_user.id
               })

      assert length(results) == 1
      assert hd(results).id == another_older_application.id
    end

    test "can filter job applications by tags", %{
      job_posting: job_posting,
      user: user
    } do
      application_1 = job_application_fixture(user, job_posting)
      application_2 = job_application_fixture(user, job_posting)
      application_3 = job_application_fixture(user, job_posting)

      JobApplications.update_job_application_tags(application_1, "urgent,qualified")
      JobApplications.update_job_application_tags(application_2, "urgent,qualified,interview")
      JobApplications.update_job_application_tags(application_3, "not_urgent,not_qualified")

      result_ids =
        %{tags: ["urgent", "qualified", "interview"]}
        |> JobApplications.list_job_applications()
        |> Enum.map(& &1.id)

      assert application_1.id in result_ids
      assert application_2.id in result_ids
      assert application_3.id not in result_ids

      result_ids_2 =
        %{tags: ["not_urgent"]}
        |> JobApplications.list_job_applications()
        |> Enum.map(& &1.id)

      assert application_1.id not in result_ids_2
      assert application_2.id not in result_ids_2
      assert application_3.id in result_ids_2

      result_ids_3 =
        %{tags: ["new_tag"]}
        |> JobApplications.list_job_applications()
        |> Enum.map(& &1.id)

      assert Enum.empty?(result_ids_3)
    end

    test "can filter job applications by state" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      job_application1 = job_application_fixture(user, job_posting)
      job_application2 = job_application_fixture(user, job_posting)
      job_application3 = job_application_fixture(user, job_posting)

      {:ok, updated_application2} =
        JobApplications.update_job_application_status(job_application2, user, %{
          "to_state" => "offer_extended"
        })

      {:ok, updated_application3} =
        JobApplications.update_job_application_status(job_application3, user, %{
          "to_state" => "offer_extended"
        })

      {:ok, accepted_application3} =
        JobApplications.update_job_application_status(updated_application3, user, %{
          "to_state" => "offer_accepted"
        })

      results = JobApplications.list_job_applications(%{state: "applied"})
      assert Enum.any?(results, fn app -> app.id == job_application1.id end)
      assert Enum.all?(results, fn app -> app.state == "applied" end)

      assert [result] = JobApplications.list_job_applications(%{state: "offer_extended"})
      assert result.id == updated_application2.id
      assert result.state == "offer_extended"

      assert [result] = JobApplications.list_job_applications(%{state: "offer_accepted"})
      assert result.id == accepted_application3.id
      assert result.state == "offer_accepted"

      assert %{state: "withdrawn"}
             |> JobApplications.list_job_applications()
             |> Enum.empty?()

      assert [result] =
               JobApplications.list_job_applications(%{
                 state: "offer_accepted",
                 user_id: user.id,
                 job_posting_id: job_posting.id
               })

      assert result.id == accepted_application3.id
      assert result.state == "offer_accepted"
      assert result.user_id == user.id
      assert result.job_posting_id == job_posting.id

      assert %{
               state: "offer_accepted",
               user_id: Ecto.UUID.generate()
             }
             |> JobApplications.list_job_applications()
             |> Enum.empty?()
    end
  end

  describe "get_user_job_application/2" do
    setup [:create_job_posting]

    test "returns the job_application for a user and job posting", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      result = JobApplications.get_user_job_application(user, job_posting)
      assert result.id == job_application.id
      assert result.user_id == user.id
      assert result.job_posting_id == job_posting.id
      assert Ecto.assoc_loaded?(result.media_asset)
    end

    test "returns the job_application with media asset" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      job_application = job_application_fixture(user, job_posting)

      media_data = %{
        "file_name" => "user_app_file.mp4",
        "status" => "uploaded",
        "type" => "video/mp4"
      }

      {:ok, _asset} =
        BemedaPersonal.Media.create_media_asset(job_application, media_data)

      result = JobApplications.get_user_job_application(user, job_posting)
      assert result.id == job_application.id
      assert result.media_asset
      assert result.media_asset.file_name == "user_app_file.mp4"
    end

    test "returns nil when a user has not applied to a job posting", %{job_posting: job_posting} do
      another_user = user_fixture(%{email: "no_application@example.com"})
      refute JobApplications.get_user_job_application(another_user, job_posting)
    end
  end

  describe "update_job_application_tags/2" do
    setup [:create_job_posting]

    test "adds tags to a job application", %{job_application: job_application} do
      assert {:ok, updated_application} =
               JobApplications.update_job_application_tags(job_application, "urgent,qualified")

      tag_names = Enum.map(updated_application.tags, & &1.name)
      assert ["urgent", "qualified"] = tag_names
      assert length(updated_application.tags) == 2
    end

    test "handles duplicate tags", %{job_application: job_application} do
      assert {:ok, application_with_new_tag} =
               JobApplications.update_job_application_tags(
                 job_application,
                 "urgent,urgent,qualified,interview"
               )

      tag_names = Enum.map(application_with_new_tag.tags, & &1.name)
      assert ["interview", "qualified", "urgent"] = Enum.sort(tag_names)
      assert length(application_with_new_tag.tags) == 3
    end

    test "trims and filters empty tags", %{job_application: job_application} do
      assert {:ok, updated_application} =
               JobApplications.update_job_application_tags(
                 job_application,
                 "  urgent  ,,  ,qualified  "
               )

      tag_names = Enum.map(updated_application.tags, & &1.name)
      assert ["urgent", "qualified"] = tag_names
      assert length(updated_application.tags) == 2
    end

    test "returns application with empty tags list when no valid tags", %{
      job_application: job_application
    } do
      assert {:ok, updated_application} =
               JobApplications.update_job_application_tags(job_application, ",  ,")

      assert updated_application.tags == []
    end

    test "broadcasts update event when adding tags", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      company_topic = "job_application:company:#{job_posting.company_id}"
      user_topic = "job_application:user:#{user.id}"

      Endpoint.subscribe(company_topic)
      Endpoint.subscribe(user_topic)

      {:ok, updated_job_application} =
        JobApplications.update_job_application_tags(job_application, "urgent,qualified")

      assert_receive %Broadcast{
        event: "company_job_application_updated",
        payload: %{job_application: ^updated_job_application}
      }

      assert_receive %Broadcast{
        event: "user_job_application_updated",
        payload: %{job_application: ^updated_job_application}
      }
    end
  end

  describe "update_job_application_status/3" do
    setup do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      %{
        company: company,
        job_application: job_application,
        job_posting: job_posting,
        user: user
      }
    end

    test "successfully updates status in valid state transition", %{
      job_application: job_application,
      user: user
    } do
      assert job_application.state == "applied"

      application_topic = "job_application:user:#{job_application.user_id}"
      Endpoint.subscribe(application_topic)

      attrs = %{"to_state" => "offer_extended", "notes" => "Application looks promising"}

      assert {:ok, updated_job_application} =
               JobApplications.update_job_application_status(job_application, user, attrs)

      assert updated_job_application.state == "offer_extended"

      transitions = Repo.all(JobApplicationStateTransition)
      assert length(transitions) == 1

      transition = List.first(transitions)
      assert transition.from_state == "applied"
      assert transition.to_state == "offer_extended"
      assert transition.notes == "Application looks promising"
      assert transition.job_application_id == job_application.id
      assert transition.transitioned_by_id == user.id

      scope = Scope.for_user(job_application.user)
      messages = Chat.list_messages(scope, job_application)
      assert length(messages) == 2

      status_message = Enum.at(messages, 1)
      assert status_message.content == "offer_extended"
      assert status_message.sender_id == user.id
      assert status_message.type == :status_update

      assert_receive %Broadcast{
        event: "user_job_application_status_updated",
        topic: ^application_topic
      }
    end

    test "allows multiple transitions in sequence", %{
      job_application: job_application,
      user: user
    } do
      assert job_application.state == "applied"

      {:ok, offer_extended_application} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended"
        })

      assert offer_extended_application.state == "offer_extended"

      {:ok, offer_accepted_application} =
        JobApplications.update_job_application_status(offer_extended_application, user, %{
          "to_state" => "offer_accepted"
        })

      assert offer_accepted_application.state == "offer_accepted"

      transitions = Repo.all(JobApplicationStateTransition)
      assert length(transitions) == 2

      scope = Scope.for_user(job_application.user)
      messages = Chat.list_messages(scope, job_application)
      assert length(messages) == 3
    end

    test "fails when trying to skip states", %{
      job_application: job_application,
      user: user
    } do
      assert job_application.state == "applied"

      attrs = %{"to_state" => "offer_accepted"}

      {:error, changeset} =
        JobApplications.update_job_application_status(job_application, user, attrs)

      assert "transition_changeset failed: invalid transition from applied to offer_accepted" in errors_on(
               changeset
             ).state

      assert Repo.all(JobApplicationStateTransition) == []

      scope = Scope.for_user(job_application.user)
      messages = Chat.list_messages(scope, job_application)
      assert length(messages) == 1
    end

    test "fails when trying to transition to an invalid state", %{
      job_application: job_application,
      user: user
    } do
      attrs = %{"to_state" => "invalid_state"}
      result = JobApplications.update_job_application_status(job_application, user, attrs)

      assert {:error, changeset} = result

      assert "transition_changeset failed: invalid transition from applied to invalid_state" in errors_on(
               changeset
             ).state

      assert Repo.all(JobApplicationStateTransition) == []

      scope = Scope.for_user(job_application.user)
      messages = Chat.list_messages(scope, job_application)
      assert length(messages) == 1
    end

    test "successfully transitions to withdrawn state from any state", %{
      job_application: job_application,
      user: user
    } do
      {:ok, updated_job_application} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended"
        })

      assert updated_job_application.state == "offer_extended"

      {:ok, withdrawn_application} =
        JobApplications.update_job_application_status(updated_job_application, user, %{
          "to_state" => "withdrawn"
        })

      assert withdrawn_application.state == "withdrawn"

      transitions = Repo.all(JobApplicationStateTransition)
      assert length(transitions) == 2

      scope = Scope.for_user(job_application.user)
      messages = Chat.list_messages(scope, job_application)
      assert length(messages) == 3
    end
  end

  describe "change_job_application_status/2" do
    setup do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      {:ok, updated_application} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended"
        })

      transitions = JobApplications.list_job_application_state_transitions(updated_application)
      transition = List.first(transitions)

      %{
        transition: transition
      }
    end

    test "returns a job_application_state_transition changeset", %{transition: transition} do
      assert %Ecto.Changeset{} = JobApplications.change_job_application_status(transition)
    end

    test "returns a changeset with changes when valid attrs are provided", %{
      transition: transition
    } do
      changeset =
        JobApplications.change_job_application_status(transition, %{"notes" => "Updated notes"})

      assert changeset.valid?
      assert changeset.changes[:notes] == "Updated notes"
    end

    test "returns a changeset with errors when invalid attrs are provided", %{
      transition: transition
    } do
      changeset =
        JobApplications.change_job_application_status(transition, %{
          "from_state" => nil,
          "to_state" => nil
        })

      refute changeset.valid?
      assert errors_on(changeset)[:from_state]
      assert errors_on(changeset)[:to_state]
    end
  end

  describe "list_job_application_state_transitions/1" do
    setup do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      {:ok, offer_extended_app} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended",
          "notes" => "Moving to offer extended"
        })

      {:ok, offer_accepted_app} =
        JobApplications.update_job_application_status(offer_extended_app, user, %{
          "to_state" => "offer_accepted",
          "notes" => "Moving to offer accepted"
        })

      other_application = job_application_fixture(user, job_posting)

      %{
        user: user,
        job_application: offer_accepted_app,
        other_application: other_application
      }
    end

    test "returns a list of state transitions for a job application", %{
      job_application: job_application
    } do
      transitions = JobApplications.list_job_application_state_transitions(job_application)

      assert length(transitions) == 2

      [first, second] = transitions

      assert first.to_state == "offer_extended"
      assert first.notes == "Moving to offer extended"

      assert second.to_state == "offer_accepted"
      assert second.notes == "Moving to offer accepted"

      Enum.each(transitions, fn transition ->
        assert Ecto.assoc_loaded?(transition.transitioned_by)
      end)
    end

    test "returns an empty list for job application with no transitions", %{
      other_application: other_application
    } do
      transitions = JobApplications.list_job_application_state_transitions(other_application)
      assert Enum.empty?(transitions)
    end
  end

  describe "user_has_applied_to_company_job?/2" do
    test "returns true when user has applied to a job at the company" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      assert JobApplications.user_has_applied_to_company_job?(user.id, company.id)
    end

    test "returns false when user has not applied to any job at the company" do
      user = employer_user_fixture()
      company = company_fixture(user)
      _job_posting = job_posting_fixture(company)

      refute JobApplications.user_has_applied_to_company_job?(user.id, company.id)
    end

    test "returns false when user has applied to jobs at other companies but not this one" do
      user = user_fixture()
      employer1 = employer_user_fixture()
      employer2 = employer_user_fixture()

      company1 = company_fixture(employer1)
      job_posting1 = job_posting_fixture(company1)
      _job_application1 = job_application_fixture(user, job_posting1)

      company2 = company_fixture(employer2)
      _job_posting2 = job_posting_fixture(company2)

      assert JobApplications.user_has_applied_to_company_job?(user.id, company1.id)
      refute JobApplications.user_has_applied_to_company_job?(user.id, company2.id)
    end

    test "returns true when user has applied to multiple jobs at the same company" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company)
      job_posting2 = job_posting_fixture(company)

      _job_application1 = job_application_fixture(user, job_posting1)
      _job_application2 = job_application_fixture(user, job_posting2)

      assert JobApplications.user_has_applied_to_company_job?(user.id, company.id)
    end

    test "returns false for non-existent user" do
      company = company_fixture(employer_user_fixture())
      non_existent_user_id = Ecto.UUID.generate()

      refute JobApplications.user_has_applied_to_company_job?(non_existent_user_id, company.id)
    end

    test "returns false for non-existent company" do
      user = user_fixture()
      non_existent_company_id = Ecto.UUID.generate()

      refute JobApplications.user_has_applied_to_company_job?(user.id, non_existent_company_id)
    end

    test "returns true regardless of job application status" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      assert JobApplications.user_has_applied_to_company_job?(user.id, company.id)

      {:ok, updated_application} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended"
        })

      assert JobApplications.user_has_applied_to_company_job?(user.id, company.id)

      {:ok, _withdrawn_application} =
        JobApplications.update_job_application_status(updated_application, user, %{
          "to_state" => "withdrawn"
        })

      assert JobApplications.user_has_applied_to_company_job?(user.id, company.id)
    end

    test "returns correct results for multiple users and companies" do
      employer1 = employer_user_fixture(%{email: "employer1@example.com"})
      employer2 = employer_user_fixture(%{email: "employer2@example.com"})
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})

      company1 = company_fixture(employer1)
      company2 = company_fixture(employer2)
      job_posting1 = job_posting_fixture(company1)
      job_posting2 = job_posting_fixture(company2)
      _job_application1 = job_application_fixture(user1, job_posting1)
      _job_application2 = job_application_fixture(user2, job_posting2)

      assert JobApplications.user_has_applied_to_company_job?(user1.id, company1.id)
      refute JobApplications.user_has_applied_to_company_job?(user1.id, company2.id)
      refute JobApplications.user_has_applied_to_company_job?(user2.id, company1.id)
      assert JobApplications.user_has_applied_to_company_job?(user2.id, company2.id)
    end
  end

  describe "count_user_applications/1" do
    test "returns 0 when user has no applications" do
      user = user_fixture()

      assert JobApplications.count_user_applications(user.id) == 0
    end

    test "returns correct count when user has one application" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      assert JobApplications.count_user_applications(user.id) == 1
    end

    test "returns correct count when user has multiple applications" do
      user = employer_user_fixture()
      company = company_fixture(user)

      # Create 3 job postings and applications
      job_posting1 = job_posting_fixture(company)
      job_posting2 = job_posting_fixture(company)
      job_posting3 = job_posting_fixture(company)

      _job_application1 = job_application_fixture(user, job_posting1)
      _job_application2 = job_application_fixture(user, job_posting2)
      _job_application3 = job_application_fixture(user, job_posting3)

      assert JobApplications.count_user_applications(user.id) == 3
    end

    test "only counts applications for the specified user" do
      employer = employer_user_fixture(%{email: "employer@example.com"})
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      # Create applications for both users
      _job_application1 = job_application_fixture(user1, job_posting)
      _job_application2 = job_application_fixture(user2, job_posting)

      assert JobApplications.count_user_applications(user1.id) == 1
      assert JobApplications.count_user_applications(user2.id) == 1
    end

    test "counts applications regardless of their status" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting1 = job_posting_fixture(company)
      job_posting2 = job_posting_fixture(company)

      job_application1 = job_application_fixture(user, job_posting1)
      job_application2 = job_application_fixture(user, job_posting2)

      # Update one application to withdrawn status
      {:ok, _withdrawn_app} =
        JobApplications.update_job_application_status(job_application1, user, %{
          "to_state" => "withdrawn"
        })

      # Update another to offer_extended
      {:ok, _offer_app} =
        JobApplications.update_job_application_status(job_application2, user, %{
          "to_state" => "offer_extended"
        })

      # Should still count both applications
      assert JobApplications.count_user_applications(user.id) == 2
    end

    test "accepts user_id as string or binary" do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      _job_application = job_application_fixture(user, job_posting)

      # Test with binary UUID
      assert JobApplications.count_user_applications(user.id) == 1

      # Test with string (though typically it's always binary in Ecto)
      assert user.id
             |> to_string()
             |> JobApplications.count_user_applications() == 1
    end
  end

  describe "get_latest_withdraw_state_transition/1" do
    setup do
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      %{
        company: company,
        job_application: job_application,
        job_posting: job_posting,
        user: user
      }
    end

    test "returns nil when job application has no withdrawn transitions", %{
      job_application: job_application,
      user: user
    } do
      {:ok, _updated_application} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "offer_extended"
        })

      refute JobApplications.get_latest_withdraw_state_transition(job_application)
    end

    test "returns the latest withdrawn transition when it exists", %{
      job_application: job_application,
      user: user
    } do
      {:ok, updated_application} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "withdrawn",
          "notes" => "Withdrawing application"
        })

      transition = JobApplications.get_latest_withdraw_state_transition(updated_application)

      assert %JobApplicationStateTransition{} = transition
      assert transition.to_state == "withdrawn"
      assert transition.notes == "Withdrawing application"
      assert transition.job_application_id == job_application.id
    end

    test "returns the most recent withdrawn transition when multiple exist", %{
      job_application: job_application,
      user: user
    } do
      first_timestamp = DateTime.from_naive!(~N[2023-01-01 10:00:00], "Etc/UTC")
      second_timestamp = DateTime.from_naive!(~N[2023-01-01 12:00:00], "Etc/UTC")
      third_timestamp = DateTime.from_naive!(~N[2023-01-01 14:00:00], "Etc/UTC")

      {:ok, withdrawn_app_1} =
        JobApplications.update_job_application_status(job_application, user, %{
          "to_state" => "withdrawn",
          "notes" => "First withdrawal"
        })

      first_transition = JobApplications.get_latest_withdraw_state_transition(withdrawn_app_1)

      first_transition
      |> Ecto.Changeset.change(%{inserted_at: first_timestamp})
      |> Repo.update()

      {:ok, reapplied_app} =
        JobApplications.update_job_application_status(withdrawn_app_1, user, %{
          "to_state" => "applied"
        })

      reapply_transitions = JobApplications.list_job_application_state_transitions(reapplied_app)

      reapply_transition =
        Enum.find(
          reapply_transitions,
          &(&1.to_state == "applied" and &1.from_state == "withdrawn")
        )

      reapply_transition
      |> Ecto.Changeset.change(%{inserted_at: second_timestamp})
      |> Repo.update()

      {:ok, withdrawn_app_2} =
        JobApplications.update_job_application_status(reapplied_app, user, %{
          "to_state" => "withdrawn",
          "notes" => "Second withdrawal"
        })

      second_transition = JobApplications.get_latest_withdraw_state_transition(withdrawn_app_2)

      second_transition
      |> Ecto.Changeset.change(%{inserted_at: third_timestamp})
      |> Repo.update()

      final_transition = JobApplications.get_latest_withdraw_state_transition(withdrawn_app_2)

      assert %JobApplicationStateTransition{} = final_transition
      assert final_transition.to_state == "withdrawn"
      assert final_transition.notes == "Second withdrawal"
      assert final_transition.job_application_id == job_application.id

      all_transitions = JobApplications.list_job_application_state_transitions(withdrawn_app_2)
      withdrawn_transitions = Enum.filter(all_transitions, &(&1.to_state == "withdrawn"))
      assert length(withdrawn_transitions) == 2
    end

    test "returns nil for job application with no state transitions", %{
      user: user,
      job_posting: job_posting
    } do
      new_job_application = job_application_fixture(user, job_posting)

      refute JobApplications.get_latest_withdraw_state_transition(new_job_application)
    end
  end

  # Scope-based TDD Tests - Dual Authorization Patterns
  setup :setup_scope_tests

  defp setup_scope_tests(_context) do
    # Create employer scope (company owner)
    employer_scope = employer_scope_fixture()
    job_posting = job_posting_fixture(employer_scope.company)

    # Create job seeker scope (applicant)
    job_seeker_scope = job_seeker_scope_fixture()

    # Create application
    job_application = job_application_fixture(job_seeker_scope.user, job_posting)

    # Create other scopes for negative testing
    other_employer_scope = employer_scope_fixture()
    other_job_seeker_scope = job_seeker_scope_fixture()

    %{
      employer_scope: employer_scope,
      job_seeker_scope: job_seeker_scope,
      other_employer_scope: other_employer_scope,
      other_job_seeker_scope: other_job_seeker_scope,
      job_posting: job_posting,
      job_application: job_application
    }
  end

  describe "list_job_applications/1 (scope-based)" do
    test "employer scope returns applications for their company's job postings", %{
      employer_scope: employer_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based list
      results = JobApplications.list_job_applications(employer_scope)

      # Employer should see applications to their job postings
      assert Enum.any?(results, &(&1.id == job_application.id))
    end

    test "job seeker scope returns their own applications only", %{
      job_seeker_scope: job_seeker_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based list
      results = JobApplications.list_job_applications(job_seeker_scope)

      # Job seeker should see their own applications
      assert Enum.any?(results, &(&1.id == job_application.id))

      # Should only contain applications from this user
      assert Enum.all?(results, &(&1.user_id == job_seeker_scope.user.id))
    end

    test "other employer scope does not see applications to different companies", %{
      other_employer_scope: other_employer_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based list
      results = JobApplications.list_job_applications(other_employer_scope)

      # Other employer should not see this application
      refute Enum.any?(results, &(&1.id == job_application.id))
    end

    test "other job seeker scope does not see different user's applications", %{
      other_job_seeker_scope: other_job_seeker_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based list
      results = JobApplications.list_job_applications(other_job_seeker_scope)

      # Other job seeker should not see this application
      refute Enum.any?(results, &(&1.id == job_application.id))
    end

    test "nil scope returns empty list" do
      # RED phase: This will fail until we implement scope-based list
      results = JobApplications.list_job_applications(nil)
      assert results == []
    end
  end

  describe "get_job_application!/2 (scope-based)" do
    test "employer scope can access applications to their job postings", %{
      employer_scope: employer_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based get
      result = JobApplications.get_job_application!(employer_scope, job_application.id)
      assert result.id == job_application.id
    end

    test "job seeker scope can access their own applications", %{
      job_seeker_scope: job_seeker_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based get
      result = JobApplications.get_job_application!(job_seeker_scope, job_application.id)
      assert result.id == job_application.id
    end

    test "other employer scope cannot access applications to different companies", %{
      other_employer_scope: other_employer_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based get
      assert_raise Ecto.NoResultsError, fn ->
        JobApplications.get_job_application!(other_employer_scope, job_application.id)
      end
    end

    test "other job seeker scope cannot access different user's applications", %{
      other_job_seeker_scope: other_job_seeker_scope,
      job_application: job_application
    } do
      # RED phase: This will fail until we implement scope-based get
      assert_raise Ecto.NoResultsError, fn ->
        JobApplications.get_job_application!(other_job_seeker_scope, job_application.id)
      end
    end

    test "nil scope cannot access applications" do
      # RED phase: This will fail until we implement scope-based get
      assert_raise Ecto.NoResultsError, fn ->
        JobApplications.get_job_application!(nil, Ecto.UUID.generate())
      end
    end
  end

  describe "create_job_application/3 (scope-based)" do
    test "job seeker scope can create applications", %{
      job_seeker_scope: job_seeker_scope,
      job_posting: job_posting
    } do
      attrs = %{"cover_letter" => "Test cover letter"}

      # RED phase: This will fail until we implement scope-based create
      assert {:ok, %JobApplication{} = job_application} =
               JobApplications.create_job_application(job_seeker_scope, job_posting, attrs)

      assert job_application.cover_letter == "Test cover letter"
      assert job_application.user_id == job_seeker_scope.user.id
      assert job_application.job_posting_id == job_posting.id
    end

    test "employer scope cannot create applications", %{
      employer_scope: employer_scope,
      job_posting: job_posting
    } do
      attrs = %{"cover_letter" => "Test cover letter"}

      # RED phase: This will fail until we implement scope-based create
      assert {:error, :unauthorized} =
               JobApplications.create_job_application(employer_scope, job_posting, attrs)
    end

    test "nil scope cannot create applications", %{job_posting: job_posting} do
      attrs = %{"cover_letter" => "Test cover letter"}

      # RED phase: This will fail until we implement scope-based create
      assert {:error, :unauthorized} =
               JobApplications.create_job_application(nil, job_posting, attrs)
    end
  end

  describe "update_job_application/3 (scope-based)" do
    test "job seeker scope can update their own applications", %{
      job_seeker_scope: job_seeker_scope,
      job_application: job_application
    } do
      attrs = %{"cover_letter" => "Updated cover letter"}

      # RED phase: This will fail until we implement scope-based update
      assert {:ok, %JobApplication{} = updated_application} =
               JobApplications.update_job_application(job_seeker_scope, job_application, attrs)

      assert updated_application.cover_letter == "Updated cover letter"
      assert updated_application.id == job_application.id
    end

    test "employer scope can update applications to their job postings", %{
      employer_scope: employer_scope,
      job_application: job_application
    } do
      # Only certain fields can be updated by employers
      attrs = %{"internal_notes" => "Updated internal notes"}

      # RED phase: This will fail until we implement scope-based update
      assert {:ok, %JobApplication{} = updated_application} =
               JobApplications.update_job_application(employer_scope, job_application, attrs)

      assert updated_application.id == job_application.id
    end

    test "other job seeker scope cannot update different user's applications", %{
      other_job_seeker_scope: other_job_seeker_scope,
      job_application: job_application
    } do
      attrs = %{"cover_letter" => "Malicious update"}

      # RED phase: This will fail until we implement scope-based update
      assert {:error, :unauthorized} =
               JobApplications.update_job_application(
                 other_job_seeker_scope,
                 job_application,
                 attrs
               )
    end

    test "other employer scope cannot update applications to different companies", %{
      other_employer_scope: other_employer_scope,
      job_application: job_application
    } do
      attrs = %{"internal_notes" => "Malicious update"}

      # RED phase: This will fail until we implement scope-based update
      assert {:error, :unauthorized} =
               JobApplications.update_job_application(
                 other_employer_scope,
                 job_application,
                 attrs
               )
    end

    test "nil scope cannot update applications", %{job_application: job_application} do
      attrs = %{"cover_letter" => "Malicious update"}

      # RED phase: This will fail until we implement scope-based update
      assert {:error, :unauthorized} =
               JobApplications.update_job_application(nil, job_application, attrs)
    end
  end

  describe "update_job_application_status/4 (scope-based)" do
    test "employer scope can update status on applications to their job postings", %{
      employer_scope: employer_scope,
      job_application: job_application
    } do
      attrs = %{"to_state" => "offer_extended", "notes" => "Great candidate"}

      # RED phase: This will fail until we implement scope-based status update
      assert {:ok, %JobApplication{} = updated_application} =
               JobApplications.update_job_application_status(
                 employer_scope,
                 job_application,
                 attrs
               )

      assert updated_application.state == "offer_extended"
    end

    test "job seeker scope can withdraw their own applications", %{
      job_seeker_scope: job_seeker_scope,
      job_application: job_application
    } do
      attrs = %{"to_state" => "withdrawn", "notes" => "Found another opportunity"}

      # RED phase: This will fail until we implement scope-based status update
      assert {:ok, %JobApplication{} = updated_application} =
               JobApplications.update_job_application_status(
                 job_seeker_scope,
                 job_application,
                 attrs
               )

      assert updated_application.state == "withdrawn"
    end

    test "job seeker scope cannot change status to employer-only states", %{
      job_seeker_scope: job_seeker_scope,
      job_application: job_application
    } do
      attrs = %{"to_state" => "offer_extended"}

      # RED phase: This will fail until we implement scope-based status update
      assert {:error, :unauthorized} =
               JobApplications.update_job_application_status(
                 job_seeker_scope,
                 job_application,
                 attrs
               )
    end

    test "other employer scope cannot update status on different company applications", %{
      other_employer_scope: other_employer_scope,
      job_application: job_application
    } do
      attrs = %{"to_state" => "offer_extended"}

      # RED phase: This will fail until we implement scope-based status update
      assert {:error, :unauthorized} =
               JobApplications.update_job_application_status(
                 other_employer_scope,
                 job_application,
                 attrs
               )
    end
  end
end
