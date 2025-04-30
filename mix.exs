defmodule BemedaPersonal.MixProject do
  use Mix.Project

  @spec project() :: keyword()
  def project do
    [
      app: :bemeda_personal,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: phoenix_deps() ++ optimum_deps() ++ app_deps(),

      # CI
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      preferred_cli_env: [
        check_code: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        credo: :test,
        dialyzer: :test,
        sobelow: :test
      ],
      test_coverage: [tool: ExCoveralls],

      # Docs
      name: "BemedaPersonal",
      source_url: "https://github.com/3Stones-io/bemeda_personal",
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "main"
      ],

      # Release
      releases: [
        bemeda_personal: [
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  @spec application() :: keyword()
  def application do
    [
      mod: {BemedaPersonal.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_other), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp app_deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:mdex, "~> 0.4.0"},
      {:multipart, "~> 0.4"},
      {:number, "~> 1.0"},
      {:plug, "~> 1.17"},
      {:tidewave, "~> 0.1", only: :dev}
    ]
  end

  defp optimum_deps do
    [
      {:appsignal_phoenix, "~> 2.3"},
      {:credo, "~> 1.7", only: :test, runtime: false},
      {:dialyxir, "~> 1.4", only: :test, runtime: false},
      {:doctest_formatter, "~> 0.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:ex_machina, "~> 2.7", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:faker, "~> 0.18", only: :test},
      {:github_workflows_generator, "~> 0.1", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: :test, runtime: false},
      {:optimum_credo, "~> 0.1", github: "optimumBA/optimum_credo", only: :test, runtime: false},
      {:sobelow, "~> 0.13", only: :test, runtime: false}
    ]
  end

  defp phoenix_deps do
    [
      {:phoenix, "~> 1.7.19"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [
        "deps.get",
        "cmd npm i -D prettier",
        "ecto.setup",
        "assets.setup",
        "assets.build"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd --cd assets npm install"
      ],
      "assets.build": ["tailwind bemeda_personal", "esbuild bemeda_personal"],
      "assets.deploy": [
        "tailwind bemeda_personal --minify",
        "esbuild bemeda_personal --minify",
        "phx.digest"
      ],
      check_code: [
        "deps.unlock --check-unused",
        # TODO: Remove the flag once the hackney issue is fixed
        "deps.audit --ignore-advisory-ids \"GHSA-vq52-99r9-h5pw\"",
        "hex.audit",
        "sobelow --config .sobelow-conf",
        "format --check-formatted",
        "cmd npx prettier -c .",
        "credo --strict",
        "dialyzer",
        "test --cover --warnings-as-errors"
      ],
      prettier: ["cmd npx prettier -w ."]
    ]
  end
end
