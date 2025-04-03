alias BemedaPersonal.Accounts
alias BemedaPersonal.Companies
alias BemedaPersonal.Jobs

{:ok, user1} =
  Accounts.register_user(%{
    email: "john.doe@example.com",
    password: "password123456",
    first_name: "John",
    last_name: "Doe"
  })

{:ok, user2} =
  Accounts.register_user(%{
    email: "jane.smith@example.com",
    password: "password123456",
    first_name: "Jane",
    last_name: "Smith"
  })

{:ok, company1} =
  Companies.create_company(user1, %{
    name: "TechInnovate",
    description: "A leading technology company focused on innovative solutions for businesses.",
    industry: "Technology",
    size: "51-200",
    website_url: "https://techinnovate.example.com",
    location: "San Francisco, CA",
    logo_url: "https://via.placeholder.com/150?text=TechInnovate"
  })

{:ok, company2} =
  Companies.create_company(user2, %{
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
    employment_type: "Full-time",
    experience_level: "Senior",
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
    employment_type: "Full-time",
    experience_level: "Mid-level",
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
    employment_type: "Full-time",
    experience_level: "Mid-level",
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
    employment_type: "Full-time",
    experience_level: "Senior",
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
    employment_type: "Full-time",
    experience_level: "Mid-level",
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
    employment_type: "Full-time",
    experience_level: "Senior",
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
    employment_type: "Full-time",
    experience_level: "Mid-level",
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
    employment_type: "Full-time",
    experience_level: "Mid-level",
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
    employment_type: "Full-time",
    experience_level: "Senior",
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
    employment_type: "Full-time",
    experience_level: "Mid-level",
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

    level = Enum.random(["Junior", "Mid-level", "Senior", "Lead"])
    tech = Enum.random(["React", "Node.js", "Python", "AWS", "Go", "Elixir", "Ruby", "Java"])

    %{
      title: "#{level} #{job_type} (#{tech})",
      description:
        "Join our team as a #{level} #{job_type} focusing on #{tech}. You'll be working on exciting projects in a collaborative environment. Required skills: #{tech}, teamwork, problem-solving.",
      location: Enum.random(["San Francisco, CA", "Remote", "New York, NY", "Austin, TX"]),
      employment_type: Enum.random(["Full-time", "Part-time", "Contract"]),
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

    level = Enum.random(["Junior", "Mid-level", "Senior", "Lead"])

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
      employment_type: Enum.random(["Full-time", "Part-time", "Contract"]),
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

Enum.with_index(all_tech_jobs)
|> Enum.each(fn {job_attrs, index} ->
  {:ok, job} = Jobs.create_job_posting(company1, job_attrs)
  # Make jobs have different timestamps, 2 hours apart
  update_job_inserted_at.(job, -7200 * (index + 1))
end)

Enum.with_index(all_health_jobs)
|> Enum.each(fn {job_attrs, index} ->
  {:ok, job} = Jobs.create_job_posting(company2, job_attrs)
  update_job_inserted_at.(job, -7200 * (index + 1))
end)

IO.puts("Seed data created successfully!")

IO.puts(
  "Created 2 users, 2 companies, and #{length(all_tech_jobs) + length(all_health_jobs)} job postings with different timestamps."
)
