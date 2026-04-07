# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChain.Classifier do
  @moduledoc false

  def classify_literal(:ok), do: {:__value__, :ok}
  def classify_literal({:ok, value}), do: {:__value__, value}
  def classify_literal(:error), do: :__error__
  def classify_literal({:error, reason}), do: {:__error__, reason}
  def classify_literal(nil), do: {:__value__, nil}

  def classify_literal(ast) do
    if Macro.quoted_literal?(ast), do: {:__value__, ast}, else: :__dynamic__
  end
end
