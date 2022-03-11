defmodule Timer do
  # Measure the execution time of 'exp'
  # unit = second | millisecond | microsecond | nanosecond | native
  defmacro duration(unit, do: exp) do
    quote do
      t1 = :os.system_time unquote(unit)
      unquote(exp)
      t2 = :os.system_time unquote(unit)
      t2 - t1
    end
  end
end
