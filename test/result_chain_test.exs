# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Dmitriy Pertsev

defmodule ResultChainTest do
  use ExUnit.Case, async: true
  use ResultChain

  import ResultChainTest.Helpers, warn: false

  defp eval_chain(ast) do
    {result, _binding} = Code.eval_quoted(ast, [], __ENV__)

    result
  end

  describe "tests for mixed operators" do
    test "first test for mixed operators" do
      ast = Code.string_to_quoted!(~S["10" |> parse() ~> reciprocal()])

      assert eval_chain(ast) == {:ok, 0.1}
    end

    test "raw and result-returning steps can be mixed in a pipe chain" do
      assert eval_chain(quote(do: "10" |> parse() |> reciprocal_raw() |> reciprocal())) ==
               {:ok, 10.0}
    end
  end

  describe "left ~> right expansion" do
    test "expands a strict error chain to the unchanged error tuple" do
      ast =
        quote do
          {:error, "10"} ~> reciprocal()
        end

      assert Macro.expand_once(ast, __ENV__) == quote(do: {:error, "10"})
    end
  end

  describe "left ~> right evaluation" do
    test "unwraps a literal ok tuple before calling the next step" do
      assert eval_chain(quote(do: {:ok, "10"} ~> parse_strict())) == {:ok, 10}
    end

    test "unwraps a dynamic ok result before calling the next step" do
      assert eval_chain(quote(do: parse_strict("10") ~> reciprocal())) == {:ok, 0.1}
    end

    test "short-circuits a dynamic error result before calling the next step" do
      assert eval_chain(quote(do: parse_strict("nope") ~> reciprocal())) ==
               {:error, :not_an_integer}
    end

    test "chain of 3" do
      assert eval_chain(quote(do: "10" ~> parse() ~> reciprocal() ~> reciprocal())) ==
               {:ok, 10.0}
    end

    test "print code from ast" do
      ast =
        quote do
          {:ok, "10"} ~> parse() ~> reciprocal()
        end

      out = ResultChain.code_from_ast(ast)
      IO.puts(out)
      assert true
    end

    test "narrow-typed chains compile under warnings-as-errors" do
      module = Module.concat(__MODULE__, :"WarningsAsErrors#{System.unique_integer([:positive])}")

      source = """
      defmodule #{inspect(module)} do
        use ResultChain

        def parse(_), do: {:ok, 5}
        def reciprocal(v), do: {:ok, 1 / v}

        def run, do: parse("x") ~> reciprocal() ~> reciprocal()
      end
      """

      path = Path.join(System.tmp_dir!(), "#{module}.ex")
      File.write!(path, source)

      {output, status} =
        System.cmd(
          "elixirc",
          [
            "--warnings-as-errors",
            "-pa",
            Path.join(Mix.Project.build_path(), "lib/result_chain/ebin"),
            path
          ],
          stderr_to_stdout: true
        )

      File.rm(path)
      File.rm(Path.join(File.cwd!(), "Elixir.#{module}.beam"))

      assert status == 0, output
    end
  end

  describe "special ~> boundary values" do
    test "literal and dynamic ok/error/nil values follow chain semantics" do
      module = Module.concat(__MODULE__, :"SpecialValues#{System.unique_integer([:positive])}")

      Code.compile_quoted(
        quote do
          defmodule unquote(module) do
            use ResultChain

            def accept(value), do: {:ok, value}
            def return_ok, do: :ok
            def return_error, do: :error
            def return_nil, do: nil

            def literal_ok, do: :ok ~> accept()
            def literal_error, do: :error ~> accept()
            def literal_nil, do: nil ~> accept()

            def dynamic_ok, do: return_ok() ~> accept()
            def dynamic_error, do: return_error() ~> accept()
            def dynamic_nil, do: return_nil() ~> accept()
          end
        end
      )

      assert module.literal_ok() == {:ok, :ok}
      assert module.literal_error() == :error
      assert module.literal_nil() == {:ok, nil}
      assert module.dynamic_ok() == {:ok, :ok}
      assert module.dynamic_error() == :error
      assert module.dynamic_nil() == {:ok, nil}
    end
  end

  describe "bare local calls" do
    test "custom chain operators accept bare local calls" do
      module = Module.concat(__MODULE__, :"BareLocalCalls#{System.unique_integer([:positive])}")

      Code.compile_quoted(
        quote do
          defmodule unquote(module) do
            use ResultChain

            def foo_pipe(x), do: x + 1
            def foo_chain(x), do: {:ok, x + 1}

            def run_pipe, do: 1 |> foo_pipe
            def run_chain, do: {:ok, 1} ~> foo_chain
          end
        end
      )

      assert module.run_pipe() == 2
      assert module.run_chain() == {:ok, 2}
    end
  end
end
