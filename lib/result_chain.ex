# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChain do
  @moduledoc """
  Result-aware chaining operators for Elixir workflows.

  `ResultChain` adds the `~>` operator for chaining steps that may return
  success or error values. Successful results continue to the next step, while
  errors stop the chain and are returned unchanged.

  `~>` treats values as follows:

  - `{:ok, value}` unwraps to `value` before calling the next step
  - `:ok` continues as the value `:ok`
  - `:error` short-circuits the chain and returns `:error`
  - `{:error, reason}` short-circuits the chain and returns `{:error, reason}`
  - `nil` is treated as a successful value
  - any other non-error value is treated as a successful value

  There are two ways to integrate the operators:

  - `use ResultChain` imports `ResultChain` and locally replaces `Kernel.|>/2`,
    so `|>` and `~>` can be mixed in one chain
  - `import ResultChain` imports only this module's macros, which is useful for
    `~>`-only chains

  ## Mixed chains with `use ResultChain`

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

  ## `~>`-only chains with `import ResultChain`

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
  """

  import ResultChain.ChainBuilder

  @chain_operators [:~>, :|>]

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [|>: 2]
      import ResultChain, warn: false
    end
  end

  defmacro is_chain_operator(op) do
    quote do
      unquote(op) in unquote(@chain_operators)
    end
  end

  defmacro unquote(:|>)(left, right) do
    ast = {:|>, [], [left, right]}
    chain = unpipe(ast)
    build_chain(chain)
  end

  @doc """
  Chains a value or result into the next call with result-aware short-circuiting.

  The right-hand side receives the unwrapped successful value from the left-hand
  side. If the left-hand side evaluates to `:error` or `{:error, reason}`, the
  remaining steps are skipped and that error is returned unchanged.

  Success values are:

  - `:ok`
  - `{:ok, value}`
  - `nil`
  - any other non-error value

  Failure values are:

  - `:error`
  - `{:error, reason}`

  ## Examples

  Successful chaining:

  ```elixir
  iex> import ResultChain
  iex> parse = fn value ->
  ...>   case Integer.parse(value) do
  ...>     {integer, _} -> {:ok, integer}
  ...>     _ -> {:error, :not_an_integer}
  ...>   end
  ...> end
  iex> reciprocal = fn
  ...>   0 -> {:error, :division_by_zero}
  ...>   value -> {:ok, 1 / value}
  ...> end
  iex> {:ok, "10"} ~> parse.() ~> reciprocal.()
  {:ok, 0.1}
  ```

  Short-circuiting on error:

  ```elixir
  iex> import ResultChain
  iex> reciprocal = fn value -> {:ok, 1 / value} end
  iex> {:error, :not_an_integer} ~> reciprocal.()
  {:error, :not_an_integer}
  ```
  """
  defmacro left ~> right do
    ast = {:~>, [], [left, right]}
    chain = unpipe(ast)
    build_chain(chain)
  end

  def code_from_ast(ast) do
    Macro.to_string(Macro.expand_once(ast, __ENV__))
  end

  defp unpipe(expr) do
    :lists.reverse(unpipe(expr, []))
  end

  defp unpipe({op, _, [left, right]}, acc) when is_chain_operator(op) do
    unpipe({op, right}, unpipe(left, acc))
  end

  defp unpipe({op, other}, acc) when is_chain_operator(op) do
    [other, op | acc]
  end

  defp unpipe(other, acc) do
    [other | acc]
  end
end
