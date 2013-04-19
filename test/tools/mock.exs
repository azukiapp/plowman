defmodule Mock do
  def run(name // nil, options // [], contents) do
    mock = new(name, options)
    try do
      contents.(mock)
    rescue
      x ->
        raise x
    after
      mock.destroy
    end
  end

  def new(module // new_module, options // []) when is_atom(module) do
    unless is_module?(module) do
      (defmodule module do; end)
      options = List.concat options, [:non_strict]
    end

    mock = defmodule new_module do
      @module module

      def module, do: @module
      def reset!, do: :meck.reset(@module)
      def destroy, do: :meck.unload(@module)

      def nc(func, args), do: :meck.num_calls(@module, func, args)

      def stubs(func, body) do
        :meck.expect(@module, func, body)
      end

      def stubs(func, args, return) do
        :meck.expect(@module, func, args, return)
      end
    end

    # Meck
    :meck.new(module, options)

    # Return module
    elem(mock, 1)
  end

  defp new_module do
    list_to_atom('mock-#{:uuid.to_string(:uuid.uuid4())}')
  end

  defp is_module?(module) when !is_atom(module) do; false; end
  defp is_module?(module) do
    try do
      module.module_info; true
    rescue
      _ -> false
    end
  end
end
