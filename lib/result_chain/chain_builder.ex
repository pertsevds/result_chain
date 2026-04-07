# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChain.ChainBuilder do
  @moduledoc false

  import ResultChain.Classifier
  import ResultChain.Wrapper

  def build_chain(chain) do
    build_first_step(chain)
  end

  # First step for |>
  defp build_first_step([left, :|>, right | tail]) do
    quote do
      unquote(build_next_step(build_call(right, left), tail))
    end
  end

  # First step for ~>
  defp build_first_step([left, :~>, right | tail]) do
    class = classify_literal(left)

    case class do
      :__error__ ->
        quote do
          :error
        end

      {:__error__, reason} ->
        quote do
          {:error, unquote(reason)}
        end

      {:__value__, value} ->
        build_value_arg_step(value, :~>, right, tail)

      :__dynamic__ ->
        build_next_step(left, [:~>, right | tail])
    end
  end

  defp build_next_step(left, []) do
    quote do
      unquote(left)
    end
  end

  defp build_next_step(left, [:|>, right | tail]) do
    quote do
      unquote(build_next_step(build_call(right, left), tail))
    end
  end

  defp build_next_step(left, [:~>, right | tail]) do
    value = Macro.unique_var(:value, __MODULE__)

    quote do
      case wrap_result(opaque(unquote(left))) do
        :__error__ ->
          :error

        {:__error__, reason} ->
          {:error, reason}

        {:__value__, unquote(value)} ->
          unquote(build_value_arg_step(value, :~>, right, tail))
      end
    end
  end

  defp build_call(expr, value) do
    Macro.pipe(value, expr, 0)
  end

  defp build_value_arg_step(value, :~>, right, []) do
    quote do
      unquote(build_call(right, value))
    end
  end

  defp build_value_arg_step(value, :~>, right, tail) do
    other = Macro.unique_var(:other, __MODULE__)
    call_expr = build_call(right, value)

    quote do
      case opaque(unquote(call_expr)) do
        :error -> :error
        {:error, error} -> {:error, error}
        unquote(other) -> unquote(build_next_step(other, tail))
      end
    end
  end
end
