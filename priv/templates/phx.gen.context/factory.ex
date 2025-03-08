defmodule <%= inspect app_module %>.Factory do
  use ExMachina.Ecto, repo: <%= inspect app_module %>.Repo

<%= for alias <- aliases do %>  alias <%= alias %>
<% end %>
end
