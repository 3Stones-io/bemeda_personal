def <%= schema.singular %>_factory do
  %<%= inspect schema.module %>{<%= for {field, _type, default_value} <- factory_defaults do %>
    <%= field %>: <%= default_value %>,<% end %><%= for assoc <- schema.assocs do %><%
      # Extract association data from tuple
      {assoc_name, field_name, _module, _table} = case assoc do
        {name, field, mod, table} -> {name, field, mod, table}
        _ -> {nil, nil, nil, nil} # Default fallback
      end

      # Convert to string for template
      assoc_str = if assoc_name, do: to_string(assoc_name), else: ""
      field_str = if field_name, do: to_string(field_name), else: ""
    %>
    <%= field_str %>: <%= if is_atom(assoc_name), do: "build(:#{assoc_str})", else: "nil" %>,<% end %>
  }
end
