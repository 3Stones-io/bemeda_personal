alias BemedaPersonal.Accounts.User
alias BemedaPersonal.Accounts
alias BemedaPersonal.Companies
alias BemedaPersonal.JobApplications
alias BemedaPersonal.JobPostings
alias BemedaPersonal.Repo

get_or_create_user = fn email, attrs ->
  case Accounts.get_user_by_email(email) do
    nil ->
      case Accounts.register_user(attrs) do
        {:ok, user} ->
          case user
               |> User.confirm_changeset()
               |> Repo.update() do
            {:ok, confirmed_user} -> confirmed_user
            {:error, _changeset} -> user
          end

        {:error, changeset} ->
          IO.puts("Failed to register user #{email}: #{inspect(changeset.errors)}")
          # If registration fails, try to get the user again (race condition)
          Accounts.get_user_by_email(email)
      end

    user ->
      user
  end
end

get_or_create_company = fn user, attrs ->
  case Companies.get_company_by_user(user) do
    nil ->
      case Companies.create_company(user, attrs) do
        {:ok, company} ->
          company

        {:error, changeset} ->
          IO.puts("Failed to create company for user #{user.email}: #{inspect(changeset.errors)}")

          Companies.get_company_by_user(user)
      end

    company ->
      company
  end
end

user1 =
  get_or_create_user.("john.doe@example.com", %{
    city: "San Francisco",
    country: "United States",
    email: "john.doe@example.com",
    first_name: "John",
    last_name: "Doe",
    password: "password123456",
    street: "123 Tech Street, Apt 4B",
    user_type: :employer,
    zip_code: "94105"
  })

user2 =
  get_or_create_user.("jane.smith@example.com", %{
    city: "Boston",
    country: "United States",
    email: "jane.smith@example.com",
    first_name: "Jane",
    last_name: "Smith",
    password: "password123456",
    street: "456 Health Avenue",
    user_type: :employer,
    zip_code: "02101"
  })

job_seeker =
  get_or_create_user.("alex.johnson@example.com", %{
    city: "Seattle",
    country: "United States",
    email: "alex.johnson@example.com",
    first_name: "Alex",
    last_name: "Johnson",
    password: "password123456",
    street: "789 Job Seeker Lane",
    user_type: :job_seeker,
    zip_code: "98101"
  })

company1 =
  get_or_create_company.(user1, %{
    name: "TechInnovate",
    description: "A leading technology company focused on innovative solutions for businesses.",
    industry: "Technology",
    size: "51-200",
    website_url: "https://techinnovate.example.com",
    location: "San Francisco, CA",
    logo_url: "https://via.placeholder.com/150?text=TechInnovate"
  })

company2 =
  get_or_create_company.(user2, %{
    name: "HealthPlus",
    description: "Revolutionizing healthcare through technology and modern approaches.",
    industry: "Healthcare",
    size: "201-500",
    website_url: "https://healthplus.example.com",
    location: "Boston, MA",
    logo_url: "https://via.placeholder.com/150?text=HealthPlus"
  })

tech_jobs = [
  %{
    title: "Senior Frontend Engineer",
    description:
      "We are looking for a Senior Frontend Engineer to join our team. You will be responsible for building user interfaces, implementing features, and ensuring a high-quality user experience. Experience with React, TypeScript, and responsive design required.",
    location: "San Francisco, CA",
    employment_type: :"Permanent Position",
    experience_level: :Senior,
    salary_min: 120_000,
    salary_max: 160_000,
    currency: "USD",
    remote_allowed: true
  },
  %{
    title: "Backend Developer (Ruby on Rails)",
    description:
      "Join our backend team to develop and maintain our Ruby on Rails applications. You will be working on API development, database optimization, and implementing new features.",
    location: "San Francisco, CA",
    employment_type: :"Permanent Position",
    experience_level: :"Mid-level",
    salary_min: 100_000,
    salary_max: 130_000,
    currency: "USD",
    remote_allowed: true
  },
  %{
    title: "DevOps Engineer",
    description:
      "We're seeking a DevOps Engineer to help us build and maintain our cloud infrastructure. Experience with AWS, Kubernetes, and CI/CD pipelines is required.",
    location: "San Francisco, CA",
    employment_type: :"Permanent Position",
    experience_level: :"Mid-level",
    salary_min: 110_000,
    salary_max: 140_000,
    currency: "USD",
    remote_allowed: true
  },
  %{
    title: "Product Manager",
    description:
      "Join our product team to drive the vision and strategy for our products. You will work closely with engineering, design, and marketing teams to deliver exceptional products.",
    location: "San Francisco, CA",
    employment_type: :"Permanent Position",
    experience_level: :Senior,
    salary_min: 130_000,
    salary_max: 170_000,
    currency: "USD",
    remote_allowed: false
  },
  %{
    title: "UX/UI Designer",
    description:
      "Design beautiful and intuitive user interfaces for our web and mobile applications. Experience with Figma, user research, and interaction design required.",
    location: "San Francisco, CA",
    employment_type: :"Permanent Position",
    experience_level: :"Mid-level",
    salary_min: 95000,
    salary_max: 125_000,
    currency: "USD",
    remote_allowed: true
  }
]

health_jobs = [
  %{
    title: "Machine Learning Engineer - Healthcare",
    description:
      "Work on cutting-edge machine learning models to improve healthcare outcomes. Experience with Python, TensorFlow, and healthcare data required.",
    location: "Boston, MA",
    employment_type: :"Permanent Position",
    experience_level: :Senior,
    salary_min: 130_000,
    salary_max: 170_000,
    currency: "USD",
    remote_allowed: true
  },
  %{
    title: "Healthcare Data Analyst",
    description:
      "Analyze healthcare data to identify trends and insights. Experience with SQL, Python, and data visualization tools required.",
    location: "Boston, MA",
    employment_type: :"Permanent Position",
    experience_level: :"Mid-level",
    salary_min: 90000,
    salary_max: 120_000,
    currency: "USD",
    remote_allowed: true
  },
  %{
    title: "Mobile App Developer (iOS)",
    description:
      "Develop our iOS mobile application for healthcare providers and patients. Experience with Swift, UIKit, and healthcare apps preferred.",
    location: "Boston, MA",
    employment_type: :"Permanent Position",
    experience_level: :"Mid-level",
    salary_min: 100_000,
    salary_max: 140_000,
    currency: "USD",
    remote_allowed: false
  },
  %{
    title: "Healthcare IT Project Manager",
    description:
      "Manage healthcare IT projects from inception to completion. Experience with healthcare systems and project management required.",
    location: "Boston, MA",
    employment_type: :"Permanent Position",
    experience_level: :Senior,
    salary_min: 110_000,
    salary_max: 150_000,
    currency: "USD",
    remote_allowed: false
  },
  %{
    title: "Backend Engineer (Python/Django)",
    description:
      "Build and maintain our healthcare platform using Python and Django. Experience with healthcare data and APIs required.",
    location: "Boston, MA",
    employment_type: :"Permanent Position",
    experience_level: :"Mid-level",
    salary_min: 100_000,
    salary_max: 135_000,
    currency: "USD",
    remote_allowed: true
  }
]

more_tech_jobs =
  for _idx <- 6..50 do
    job_type =
      Enum.random([
        "Software Engineer",
        "Data Scientist",
        "Product Designer",
        "QA Engineer",
        "Technical Writer"
      ])

    level = Enum.random([:Junior, :"Mid-level", :Senior, :Lead])
    tech = Enum.random(["React", "Node.js", "Python", "AWS", "Go", "Elixir", "Ruby", "Java"])

    %{
      title: "#{level} #{job_type} (#{tech})",
      description:
        "Join our team as a #{level} #{job_type} focusing on #{tech}. You'll be working on exciting projects in a collaborative environment. Required skills: #{tech}, teamwork, problem-solving.",
      location: Enum.random(["San Francisco, CA", "Remote", "New York, NY", "Austin, TX"]),
      employment_type:
        Enum.random([:Floater, :"Permanent Position", :"Staff Pool", :"Temporary Assignment"]),
      experience_level: level,
      salary_min: Enum.random([80000, 90000, 100_000, 110_000]),
      salary_max: Enum.random([120_000, 130_000, 150_000, 170_000]),
      currency: "USD",
      remote_allowed: Enum.random([true, false])
    }
  end

more_health_jobs =
  for _idx <- 6..50 do
    job_type =
      Enum.random([
        "Healthcare Developer",
        "Medical Data Analyst",
        "Clinical Systems Engineer",
        "Health Informatics Specialist",
        "Telemedicine Developer"
      ])

    level = Enum.random([:Junior, :"Mid-level", :Senior, :Lead])

    tech =
      Enum.random([
        "Electronic Health Records",
        "HIPAA Compliance",
        "Healthcare APIs",
        "Medical Imaging",
        "Patient Monitoring"
      ])

    %{
      title: "#{level} #{job_type} (#{tech})",
      description:
        "Join our healthcare innovation team as a #{level} #{job_type} specializing in #{tech}. You'll help improve patient care through technology. Healthcare experience preferred.",
      location: Enum.random(["Boston, MA", "Remote", "Chicago, IL", "Research Triangle, NC"]),
      employment_type:
        Enum.random([:Floater, :"Permanent Position", :"Staff Pool", :"Temporary Assignment"]),
      experience_level: level,
      salary_min: Enum.random([85000, 95000, 105_000, 115_000]),
      salary_max: Enum.random([125_000, 135_000, 155_000, 175_000]),
      currency: "USD",
      remote_allowed: Enum.random([true, false])
    }
  end

all_tech_jobs = tech_jobs ++ more_tech_jobs
all_health_jobs = health_jobs ++ more_health_jobs

time_before_or_after = fn seconds_offset ->
  DateTime.utc_now()
  |> DateTime.add(seconds_offset)
  |> DateTime.truncate(:second)
end

update_job_inserted_at = fn job, seconds_offset ->
  {:ok, updated_job} =
    job
    |> Ecto.Changeset.change(%{inserted_at: time_before_or_after.(seconds_offset)})
    |> BemedaPersonal.Repo.update()

  updated_job
end

existing_tech_jobs = JobPostings.list_job_postings(%{company_id: company1.id}, 1)
existing_health_jobs = JobPostings.list_job_postings(%{company_id: company2.id}, 1)

if Enum.empty?(existing_tech_jobs) do
  Enum.with_index(all_tech_jobs)
  |> Enum.each(fn {job_attrs, index} ->
    {:ok, job} = JobPostings.create_job_posting(company1, job_attrs)

    update_job_inserted_at.(job, -7200 * (index + 1))
  end)

  IO.puts("Created #{length(all_tech_jobs)} tech jobs for TechInnovate")
else
  IO.puts("TechInnovate already has jobs, skipping job creation")
end

if Enum.empty?(existing_health_jobs) do
  Enum.with_index(all_health_jobs)
  |> Enum.each(fn {job_attrs, index} ->
    {:ok, job} = JobPostings.create_job_posting(company2, job_attrs)
    update_job_inserted_at.(job, -7200 * (index + 1))
  end)

  IO.puts("Created #{length(all_health_jobs)} health jobs for HealthPlus")
else
  IO.puts("HealthPlus already has jobs, skipping job creation")
end

create_job_applications = fn ->
  tech_jobs_list = JobPostings.list_job_postings(%{company_id: company1.id}, 1)
  health_jobs_list = JobPostings.list_job_postings(%{company_id: company2.id}, 1)

  existing_applications = JobApplications.list_job_applications(%{user_id: job_seeker.id})

  if Enum.empty?(existing_applications) and not Enum.empty?(tech_jobs_list) and
       not Enum.empty?(health_jobs_list) do
    tech_jobs_to_apply = Enum.take(tech_jobs_list, 3)
    health_jobs_to_apply = Enum.take(health_jobs_list, 2)

    application_statuses = [:pending, :under_review, :interview_scheduled, :rejected, :accepted]

    Enum.each(tech_jobs_to_apply, fn job ->
      {:ok, _application} =
        JobApplications.create_job_application(job_seeker, job, %{
          cover_letter:
            "I am very interested in this #{job.title} position at #{job.company.name}. My background in technology and passion for innovation make me a great fit for this role. I would love to contribute to your team's success.",
          status: Enum.random(application_statuses)
        })
    end)

    Enum.each(health_jobs_to_apply, fn job ->
      {:ok, _application} =
        JobApplications.create_job_application(job_seeker, job, %{
          cover_letter:
            "I am excited about the opportunity to work as a #{job.title} at #{job.company.name}. My interest in healthcare technology and commitment to improving patient outcomes align perfectly with your mission.",
          status: Enum.random(application_statuses)
        })
    end)

    IO.puts(
      "Created #{length(tech_jobs_to_apply) + length(health_jobs_to_apply)} job applications for Alex Johnson"
    )
  else
    if not Enum.empty?(existing_applications) do
      IO.puts("Alex Johnson already has job applications, skipping application creation")
    else
      IO.puts("No jobs available to apply to, skipping application creation")
    end
  end
end

create_job_applications.()

IO.puts("Seed data is now available!")
IO.puts("Users created:")
IO.puts("  - john.doe@example.com (employer) - TechInnovate")
IO.puts("  - jane.smith@example.com (employer) - HealthPlus")
IO.puts("  - alex.johnson@example.com (job seeker) - with job applications")
