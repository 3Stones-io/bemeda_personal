defmodule <%= inspect context.module %>Test do
  use <%= inspect context.base_module %>.DataCase, async: true

  alias <%= inspect context.module %>
end
