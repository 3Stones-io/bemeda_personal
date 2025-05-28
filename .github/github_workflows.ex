defmodule GithubWorkflows do
  @moduledoc """
  Run `mix github_workflows.generate` after updating this module.
  See https://hexdocs.pm/github_workflows_generator.
  """

  @cache_version_suffix "${{ runner.os }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ steps.setup-beam.outputs.otp-version }}"
  @mix_cache_key_prefix "mix-#{@cache_version_suffix}"
  @mix_cache_path ~S"""
  _build
  deps
  """
  @npm_cache_key_prefix "npm-#{@cache_version_suffix}"
  @npm_cache_path "node_modules"
  @plt_cache_key_prefix "plt-#{@cache_version_suffix}"
  @plt_cache_path "priv/plts"

  def get do
    %{
      "main.yml" => main_workflow(),
      "pr.yml" => pr_workflow()
    }
  end

  defp main_workflow do
    [
      [
        name: "Main",
        on: [
          push: [
            branches: ["main"]
          ]
        ],
        jobs:
          elixir_ci_jobs() ++
            [
              deploy_staging_app: deploy_staging_app_job()
            ]
      ]
    ]
  end

  defp pr_workflow do
    [
      [
        name: "PR",
        on: [
          pull_request: [
            branches: ["main"],
            types: ["opened", "reopened", "synchronize"]
          ]
        ],
        jobs: elixir_ci_jobs()
      ]
    ]
  end

  defp elixir_ci_jobs do
    [
      compile: compile_job(),
      credo: credo_job(),
      deps_audit: deps_audit_job(),
      dialyzer: dialyzer_job(),
      format: format_job(),
      hex_audit: hex_audit_job(),
      migrations: migrations_job(),
      prettier: prettier_job(),
      sobelow: sobelow_job(),
      test: test_job(),
      translations: translations_job(),
      unused_deps: unused_deps_job()
    ]
  end

  defp compile_job do
    elixir_job("Install deps and compile",
      steps: [
        [
          name: "Install Elixir dependencies",
          env: [MIX_ENV: "test"],
          run: "mix deps.get"
        ],
        [
          name: "Compile",
          env: [MIX_ENV: "test"],
          run: "mix compile"
        ],
        [
          name: "Save dependencies cache",
          uses: "actions/cache/save@v4",
          with: save_cache_opts(@mix_cache_key_prefix, @mix_cache_path)
        ]
      ]
    )
  end

  defp credo_job do
    elixir_job("Credo",
      needs: :compile,
      steps: [
        [
          name: "Check code style",
          env: [MIX_ENV: "test"],
          run: "mix credo --strict"
        ]
      ]
    )
  end

  defp deploy_staging_app_job do
    [
      name: "Deploy staging app",
      needs: Enum.map(elixir_ci_jobs(), &elem(&1, 0)),
      "runs-on": "ubuntu-latest",
      permissions: [
        contents: "read",
        packages: "write",
        attestations: "write",
        "id-token": "write"
      ],
      env: [
        DOCKER_BUILDKIT: "1"
      ],
      steps: [
        checkout_step(lfs?: true),
        [
          name: "Set up Ruby",
          uses: "ruby/setup-ruby@v1",
          with: [
            "ruby-version": "3.4.1"
          ]
        ],
        [
          name: "Set up Docker Buildx for cache",
          uses: "docker/setup-buildx-action@v3"
        ],
        [
          name: "Set up SSH connection",
          env: [
            SSH_PRIVATE_KEY: "${{ secrets.SSH_PRIVATE_KEY }}"
          ],
          run: """
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          eval $(ssh-agent -s)
          ssh-add ~/.ssh/id_rsa
          ssh-keyscan ${{ secrets.SERVER_ADDR }} >> ~/.ssh/known_hosts
          """
        ],
        [
          name: "Install Kamal",
          run: "gem install kamal"
        ],
        [
          name: "Set up environment variables",
          run: """
          cat > .env.prod << EOL
          APPSIGNAL_APP_ENV=stage
          APPSIGNAL_PUSH_API_KEY=${{ secrets.APPSIGNAL_PUSH_API_KEY }}
          DATABASE_URL=postgres://postgres:${{ secrets.POSTGRES_PASSWORD }}@bemeda-personal-db:5432/bemeda_personal
          KAMAL_REGISTRY_PASSWORD=${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          MAILGUN_API_KEY=${{ secrets.MAILGUN_API_KEY }}
          MAILGUN_DOMAIN=${{ secrets.MAILGUN_DOMAIN }}
          POSTGRES_PASSWORD=${{ secrets.POSTGRES_PASSWORD }}
          SECRET_KEY_BASE=${{ secrets.SECRET_KEY_BASE }}
          TIGRIS_ACCESS_KEY_ID=${{ secrets.TIGRIS_ACCESS_KEY_ID }}
          TIGRIS_BUCKET=${{ secrets.TIGRIS_BUCKET }}
          TIGRIS_SECRET_ACCESS_KEY=${{ secrets.TIGRIS_SECRET_ACCESS_KEY }}
          EOL
          """
        ],
        [
          name: "Deploy with Kamal",
          env: [
            GIT_SHA: "${{ github.sha }}"
          ],
          run: "kamal deploy"
        ]
      ]
    ]
  end

  defp deps_audit_job do
    elixir_job("Deps audit",
      needs: :compile,
      steps: [
        [
          name: "Check for vulnerable Mix dependencies",
          env: [MIX_ENV: "test"],
          # TODO: Remove the flag once the hackney issue is fixed
          run: "mix deps.audit --ignore-advisory-ids \"GHSA-vq52-99r9-h5pw\""
        ]
      ]
    )
  end

  defp dialyzer_job do
    elixir_job("Dialyzer",
      needs: :compile,
      steps: [
        [
          name: "Restore PLT cache",
          uses: "actions/cache/restore@v4",
          with: cache_opts(@plt_cache_key_prefix, @plt_cache_path)
        ],
        [
          name: "Create PLTs",
          env: [MIX_ENV: "test"],
          run: "mix dialyzer --plt"
        ],
        [
          name: "Run dialyzer",
          env: [MIX_ENV: "test"],
          run: "mix dialyzer"
        ],
        [
          name: "Save PLT cache",
          uses: "actions/cache/save@v4",
          with: save_cache_opts(@plt_cache_key_prefix, @plt_cache_path)
        ]
      ]
    )
  end

  defp elixir_job(name, opts) do
    lfs? = Keyword.get(opts, :lfs?, false)
    needs = Keyword.get(opts, :needs)
    services = Keyword.get(opts, :services)
    steps = Keyword.get(opts, :steps, [])

    job = [
      name: name,
      "runs-on": "ubuntu-latest",
      steps:
        [
          checkout_step(lfs?: lfs?),
          [
            id: "setup-beam",
            name: "Set up Elixir",
            uses: "erlef/setup-beam@v1",
            with: [
              "version-file": ".tool-versions",
              "version-type": "strict"
            ]
          ],
          [
            name: "Restore dependencies cache",
            uses: "actions/cache/restore@v4",
            with: cache_opts(@mix_cache_key_prefix, @mix_cache_path)
          ]
        ] ++ steps
    ]

    job
    |> then(fn job ->
      if needs do
        Keyword.put(job, :needs, needs)
      else
        job
      end
    end)
    |> then(fn job ->
      if services do
        Keyword.put(job, :services, services)
      else
        job
      end
    end)
  end

  defp format_job do
    elixir_job("Format",
      needs: :compile,
      steps: [
        [
          name: "Check Elixir formatting",
          env: [MIX_ENV: "test"],
          run: "mix format --check-formatted"
        ]
      ]
    )
  end

  defp hex_audit_job do
    elixir_job("Hex audit",
      needs: :compile,
      steps: [
        [
          name: "Check for retired Hex packages",
          env: [MIX_ENV: "test"],
          run: "mix hex.audit"
        ]
      ]
    )
  end

  defp migrations_job do
    elixir_job("Migrations",
      needs: :compile,
      services: [
        db: db_service()
      ],
      steps: [
        [
          name: "Setup DB",
          env: [MIX_ENV: "test"],
          run: "mix do ecto.create --quiet, ecto.migrate --quiet"
        ],
        [
          name: "Check if migrations are reversible",
          env: [MIX_ENV: "test"],
          run: "mix ecto.rollback --all --quiet"
        ]
      ]
    )
  end

  defp prettier_job do
    [
      name: "Check formatting using Prettier",
      "runs-on": "ubuntu-latest",
      steps: [
        checkout_step(),
        [
          name: "Restore npm cache",
          uses: "actions/cache/restore@v4",
          id: "npm-cache",
          with: cache_opts(@npm_cache_key_prefix, @npm_cache_path)
        ],
        [
          name: "Install Prettier",
          if: "steps.npm-cache.outputs.cache-hit != 'true'",
          run: "npm i -D prettier"
        ],
        [
          name: "Run Prettier",
          run: "npx prettier -c ."
        ],
        [
          name: "Save npm cache",
          uses: "actions/cache/save@v4",
          with: save_cache_opts(@npm_cache_key_prefix, @npm_cache_path)
        ]
      ]
    ]
  end

  defp sobelow_job do
    elixir_job("Security check",
      needs: :compile,
      steps: [
        [
          name: "Check for security issues using sobelow",
          env: [MIX_ENV: "test"],
          run: "mix sobelow --config .sobelow-conf"
        ]
      ]
    )
  end

  defp test_job do
    elixir_job("Test",
      lfs?: true,
      needs: :compile,
      services: [
        db: db_service()
      ],
      steps: [
        [
          name: "Install LibreOffice",
          run:
            "sudo apt-get update && sudo apt-get install -y --no-install-recommends libreoffice-writer"
        ],
        [
          name: "Run tests",
          env: [
            MIX_ENV: "test"
          ],
          run: "mix test --cover --warnings-as-errors"
        ]
      ]
    )
  end

  defp translations_job do
    elixir_job("Translations",
      needs: :compile,
      steps: [
        [
          name: "Check gettext and translations",
          env: [MIX_ENV: "test"],
          run: "make check_gettext check_translations"
        ]
      ]
    )
  end

  defp unused_deps_job do
    elixir_job("Check unused deps",
      needs: :compile,
      steps: [
        [
          name: "Check for unused Mix dependencies",
          env: [MIX_ENV: "test"],
          run: "mix deps.unlock --check-unused"
        ]
      ]
    )
  end

  defp db_service do
    [
      image: "postgres:13",
      ports: ["5432:5432"],
      env: [POSTGRES_PASSWORD: "postgres"],
      options:
        "--health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5"
    ]
  end

  defp checkout_step(opts \\ []) do
    lfs? = Keyword.get(opts, :lfs?, false)

    [
      name: "Checkout",
      uses: "actions/checkout@v4",
      with: [
        lfs: if(lfs?, do: "true", else: "false")
      ]
    ]
  end

  defp cache_opts(prefix, path) do
    [
      key: "#{prefix}-${{ github.sha }}",
      path: path,
      "restore-keys": ~s"""
      #{prefix}-
      """
    ]
  end

  defp save_cache_opts(prefix, path) do
    [
      key: "#{prefix}-${{ github.sha }}",
      path: path
    ]
  end
end
