# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChain.Wrapper do
  @moduledoc false

  @doc false
  @spec opaque(term()) :: term()
  def opaque(value), do: value

  @doc false
  def wrap_result(:ok), do: {:__value__, :ok}
  def wrap_result({:ok, value}), do: {:__value__, value}
  def wrap_result(:error), do: :__error__
  def wrap_result({:error, reason}), do: {:__error__, reason}
  def wrap_result(nil), do: {:__value__, nil}
  def wrap_result(value), do: {:__value__, value}
end
