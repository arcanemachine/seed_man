# SeedMan

Save and load seed data to/from the database as compressed backup files. Useful for generating database fixtures (e.g. during development and testing).

This package was created to make local development easier when working with a remote database with legacy data. Instead of working on a remote database, the data can be replicated locally for easier setup/teardown during development and testing.

> #### Tip {: .tip}
>
> This package should probably not be used to store large tables in your project, or tables with sensitive data.
>
> In such cases, you may want to use a combination of something like [ExMachina](https://github.com/beam-community/ex_machina) and [Faker](https://github.com/elixirs/faker) to generate a fixture of synthetic data that can be used instead of mirroring large or sensitive tables to your project.

## Getting started

### Installation

Add this package to your list of dependencies in `mix.exs`, then run `mix deps.get`:

```elixir
def deps do
  [
    {:seed_man, "0.1.1", only: [:dev, :test]}
  ]
end
```

> NOTE: There is nothing to stop you from running this dependency in `:prod`. It is only excluded in this example for the sake of minimizing unnecessary dependencies in production.

### Usage

For general usage instructions, see [this project's documentation](https://hexdocs.pm/bulk_upsert/BulkUpsert.html).

#### Using seed data to generate a fixture for development and/or testing

To restore a fixture, you can add something like this to your `priv/repo/seeds.exs` file after you have dumped your initial seed data:

```elixir
SeedMan.load_schema_from_seed_file(YourProject.Repo, YourProject.Persons.Person)
```

Now, when you run `mix ecto.reset`, your backed-up seeds will be automatically loaded into your
dev/test data.

---

This project made possible by Interline Travel and Tour Inc.

https://www.perx.com/

https://www.touchdown.co.uk/

https://www.touchdownfrance.com/
