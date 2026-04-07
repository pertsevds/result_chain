# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChain do
  @moduledoc false

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
