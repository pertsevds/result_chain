# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChainTest.Helpers do
  @moduledoc false

  def parse_strict(value) do
    case Integer.parse(value) do
      {integer, _} -> {:ok, integer}
      _ -> {:error, :not_an_integer}
    end
  end

  def parse(value) do
    case Integer.parse(value) do
      {integer, _} -> integer
      _ -> :error
    end
  end

  def reciprocal(0), do: {:error, :division_by_zero}
  def reciprocal(value), do: {:ok, 1 / value}
  def reciprocal_raw(value), do: 1 / value

  def sets_error(_), do: :error
  def sets_error_strict(_), do: {:error, "Error"}
end
