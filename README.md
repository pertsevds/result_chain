# ResultChain

Result-chaining operators for Elixir.

## Usage

### Use

```elixir
defmodule MyWorkflow do
  use ResultChain

  def run(value) do
    value
    |> parse()
    ~> reciprocal()
  end
end
```

`use ResultChain` defines its own `|>/2` macro.

`use ResultChain` expands to an import that excludes `Kernel.|>/2` and then imports
`ResultChain`, so the override is local to that module.


### Import

```elixir
defmodule MyWorkflow do
  import ResultChain

  def run(value) do
    value
    ~> parse()
    ~> reciprocal()
  end
end
```

You can't mix `~>` and `|>` when you use `import`.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
