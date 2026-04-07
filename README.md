# ResultChain

Result-aware chaining operators for Elixir workflows.

## What It Does

`ResultChain` helps you compose workflows where some steps return plain values
and other steps may fail with `:error` or `{:error, reason}`.

Plain `|>` always passes its left-hand value into the next call. `ResultChain`
adds `~>`, which continues on successful values and short-circuits on errors.
When you `use ResultChain`, you can mix `|>` and `~>` in the same chain.

## Installation

Add `result_chain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:result_chain, "~> 0.1.0"}
  ]
end
```

## Usage with `use ResultChain`

Use `ResultChain` when you want to mix ordinary pipe steps with result-aware
steps in the same chain. `use ResultChain` locally replaces `Kernel.|>/2` in
that module and imports `ResultChain`.

```elixir
defmodule MyWorkflow do
  use ResultChain

  def parse(value) do
    case Integer.parse(value) do
      {integer, _} -> integer
      _ -> :error
    end
  end

  def reciprocal(0), do: {:error, :division_by_zero}
  def reciprocal(value), do: {:ok, 1 / value}

  def run(value) do
    value
    |> parse()
    ~> reciprocal()
  end
end
```

## Usage with `import ResultChain`

Import `ResultChain` when you only need `~>` and want to keep the standard
`Kernel.|>/2` out of the picture.

```elixir
defmodule MyWorkflow do
  import ResultChain

  def parse(value) do
    case Integer.parse(value) do
      {integer, _} -> {:ok, integer}
      _ -> {:error, :not_an_integer}
    end
  end

  def reciprocal(0), do: {:error, :division_by_zero}
  def reciprocal(value), do: {:ok, 1 / value}

  def run(value) do
    value
    ~> parse()
    ~> reciprocal()
  end
end
```

Do not mix `~>` and `|>` in the same chain when you only `import ResultChain`.

## Result Semantics

`~>` treats values as follows:

- `{:ok, value}` unwraps to `value` before the next call
- `:ok` continues as the value `:ok`
- `:error` stops the chain and returns `:error`
- `{:error, reason}` stops the chain and returns `{:error, reason}`
- `nil` is treated as a successful value
- any other non-error value is treated as a successful value

## License

Apache License 2.0. See [LICENSE](LICENSE).
