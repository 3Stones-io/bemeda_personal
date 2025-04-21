defmodule BemedaPersonal.S3Helper.Utils do
  @moduledoc false

  @unsignable_headers_multi_case ["x-amzn-trace-id", "X-Amzn-Trace-Id"]
  @one_week 60 * 60 * 24 * 7

  @spec presign_url(map(), atom() | String.t(), String.t(), String.t() | nil, keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def presign_url(config, http_method, bucket, object, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in, 3600)

    if expires_in > @one_week do
      {:error, "expires_in_exceeds_one_week"}
    else
      {updated_config, url} = prepare_url(config, bucket, object, opts)
      datetime_value = prepare_datetime(opts)
      updated_opts = Keyword.put(opts, :expires, expires_in)

      presigned_url(
        http_method,
        url,
        :s3,
        datetime_value,
        updated_config,
        updated_opts
      )
    end
  end

  defp prepare_url(config, bucket, object, opts) do
    virtual_host = Keyword.get(opts, :virtual_host, false)
    s3_accelerate = Keyword.get(opts, :s3_accelerate, false)
    bucket_as_host = Keyword.get(opts, :bucket_as_host, false)

    {updated_config, updated_virtual_host} =
      if s3_accelerate do
        {put_accelerate_host(config), true}
      else
        {config, virtual_host}
      end

    url = url_to_sign(bucket, object, updated_config, updated_virtual_host, bucket_as_host)

    {updated_config, url}
  end

  defp prepare_datetime(opts) do
    case Keyword.get(opts, :start_datetime, NaiveDateTime.utc_now()) do
      dt when is_struct(dt, DateTime) or is_struct(dt, NaiveDateTime) ->
        NaiveDateTime.to_erl(dt)

      # assume :calendar.datetime()
      dt ->
        dt
    end
  end

  @spec presigned_url(
          atom() | String.t(),
          String.t(),
          atom(),
          :calendar.datetime(),
          map(),
          keyword()
        ) :: {:ok, String.t()} | {:error, any()}
  defp presigned_url(
         http_method,
         url,
         service,
         datetime,
         config,
         opts
       ) do
    expires = Keyword.get(opts, :expires, 3600)
    query_params = Keyword.get(opts, :query_params, [])
    body = Keyword.get(opts, :body)
    headers = Keyword.get(opts, :headers, [])

    with {:ok, config} <- validate_config(config) do
      service_str = service_name(service)
      signed_headers = presigned_url_headers(url, headers)
      uri = URI.parse(url)
      path = uri_encode(get_path(url, service_str))

      {query_to_sign, query_for_url} =
        prepare_query_params(
          query_params,
          uri,
          service_str,
          datetime,
          config,
          expires,
          signed_headers
        )

      signature =
        compute_signature(
          http_method,
          url,
          query_to_sign,
          signed_headers,
          body,
          service_str,
          datetime,
          config
        )

      {:ok, build_presigned_url(uri, path, query_for_url, signature)}
    end
  end

  defp prepare_query_params(
         query_params,
         uri,
         service_str,
         datetime,
         config,
         expires,
         signed_headers
       ) do
    uri_query = query_from_parsed_uri(uri)

    org_query_params =
      Enum.reduce(query_params, uri_query, fn {k, v}, acc -> [{to_string(k), v} | acc] end)

    amz_query_params =
      build_amz_query_params(service_str, datetime, config, expires, signed_headers)

    query_to_sign = canonical_query_params(org_query_params ++ amz_query_params)

    amz_query_string = canonical_query_params(amz_query_params)

    query_for_url =
      if Enum.any?(org_query_params) do
        canonical_query_params(org_query_params) <> "&" <> amz_query_string
      else
        amz_query_string
      end

    {query_to_sign, query_for_url}
  end

  defp compute_signature(
         http_method,
         url,
         query_to_sign,
         signed_headers,
         body,
         service_str,
         datetime,
         config
       ) do
    signature(
      http_method,
      url,
      query_to_sign,
      signed_headers,
      body,
      service_str,
      datetime,
      config
    )
  end

  defp build_presigned_url(uri, path, query_for_url, signature) do
    "#{uri.scheme}://#{uri.authority}#{path}?#{query_for_url}&X-Amz-Signature=#{signature}"
  end

  defp signature(http_method, url, query, headers, body, service, datetime, config) do
    path = uri_encode(get_path(url, service))
    request = build_canonical_request(http_method, path, query, headers, body)
    string_to_sign = string_to_sign(request, service, datetime, config)
    generate_signature_v4(service, config, datetime, string_to_sign)
  end

  defp generate_signature_v4(service, config, datetime, string_to_sign) do
    service
    |> signing_key(datetime, config)
    |> hmac_sha256(string_to_sign)
    |> bytes_to_hex()
  end

  defp signing_key(service, datetime, config) do
    ["AWS4", config[:secret_access_key]]
    |> hmac_sha256(date(datetime))
    |> hmac_sha256(config[:region])
    |> hmac_sha256(service)
    |> hmac_sha256("aws4_request")
  end

  defp hash_sha256(nil), do: "UNSIGNED-PAYLOAD"

  defp hash_sha256(data) do
    bytes_to_hex(:crypto.hash(:sha256, data))
  end

  Code.ensure_loaded?(:crypto) || IO.warn(":crypto module failed to load")

  case function_exported?(:crypto, :mac, 4) do
    true ->
      defp hmac_sha256(key, data), do: :crypto.mac(:hmac, :sha256, key, data)

    false ->
      defp hmac_sha256(key, data), do: :crypto.hmac(:sha256, key, data)
  end

  defp date({date, _time}) do
    quasi_iso_format(date)
  end

  defp get_path(url, service)

  defp get_path(url, service) when service in ["s3", :s3] do
    base =
      url
      |> URI.parse()
      |> Map.put(:path, nil)
      |> Map.put(:query, nil)
      |> Map.put(:fragment, nil)
      |> URI.to_string()

    [_prefix, path_with_params] = String.split(url, base, parts: 2)
    [path | _rest] = String.split(path_with_params, "?", parts: 2)

    path
  end

  defp get_path(url, _service), do: URI.parse(url).path || "/"

  defp string_to_sign(request, service, datetime, config) do
    hashed_request = hash_sha256(request)

    String.trim_trailing("""
    AWS4-HMAC-SHA256
    #{amz_date(datetime)}
    #{generate_credential_scope_v4(service, config, datetime)}
    #{hashed_request}
    """)
  end

  defp uri_encode(url), do: URI.encode(url, &valid_path_char?/1)

  defp valid_path_char?(?\s), do: false
  defp valid_path_char?(?/), do: true

  defp valid_path_char?(c) do
    URI.char_unescaped?(c) && !URI.char_reserved?(c)
  end

  defp generate_credential_v4(service, config, datetime) do
    scope = generate_credential_scope_v4(service, config, datetime)
    "#{config[:access_key_id]}/#{scope}"
  end

  defp generate_credential_scope_v4(service, config, datetime) do
    "#{date(datetime)}/#{config[:region]}/#{service}/aws4_request"
  end

  defp bytes_to_hex(bytes) do
    Base.encode16(bytes, case: :lower)
  end

  defp build_canonical_request(http_method, path, query, headers, body) do
    method_str = method_string(http_method)
    http_method_str = String.upcase(method_str)
    headers_canonical = canonical_headers(headers)

    header_string =
      Enum.map_join(headers_canonical, "\n", fn {k, v} ->
        "#{k}:#{remove_dup_spaces(to_string(v))}"
      end)

    signed_headers_list = signed_headers_value(headers_canonical)

    payload =
      if body do
        hash_sha256(body)
      else
        "UNSIGNED-PAYLOAD"
      end

    IO.iodata_to_binary([
      http_method_str,
      "\n",
      path,
      "\n",
      query,
      "\n",
      header_string,
      "\n",
      "\n",
      signed_headers_list,
      "\n",
      payload
    ])
  end

  defp remove_dup_spaces(str), do: remove_dup_spaces(str, "")
  defp remove_dup_spaces(str, str), do: str

  defp remove_dup_spaces(str, _prev) do
    replaced = String.replace(str, "  ", " ")
    remove_dup_spaces(replaced, str)
  end

  defp method_string(method) do
    Atom.to_string(method)
  end

  defp canonical_query_params(params) do
    params
    |> Enum.sort(&compare_query_params/2)
    |> Enum.map_join("&", &pair/1)
  end

  defp pair({k, _value}) when is_list(k) do
    raise ArgumentError, "encode_query/1 keys cannot be lists, got: #{inspect(k)}"
  end

  defp pair({_key, v}) when is_list(v) do
    raise ArgumentError, "encode_query/1 values cannot be lists, got: #{inspect(v)}"
  end

  defp pair({k, v}) do
    key_str = Kernel.to_string(k)
    value_str = Kernel.to_string(v)
    URI.encode_www_form(key_str) <> "=" <> aws_encode_www_form(value_str)
  end

  defp aws_encode_www_form(str) when is_binary(str) do
    import Bitwise

    for <<c <- str>>, into: "" do
      case URI.char_unreserved?(c) do
        true -> <<c>>
        false -> "%" <> hex(bsr(c, 4)) <> hex(band(c, 15))
      end
    end
  end

  defp hex(n) when n <= 9, do: <<n + ?0>>
  defp hex(n), do: <<n + ?A - 10>>

  defp compare_query_params({key, value1}, {key, value2}), do: value1 < value2
  defp compare_query_params({key_1, _value1}, {key_2, _value2}), do: key_1 < key_2

  defp put_accelerate_host(config) do
    Map.put(config, :host, "s3-accelerate.amazonaws.com")
  end

  defp url_to_sign(bucket, object, config, virtual_host, bucket_as_host) do
    port = sanitized_port_component(config)

    object =
      if object do
        ensure_slash(object)
      else
        ""
      end

    scheme = config[:scheme] || "https://"
    host = config[:host] || "s3.amazonaws.com"

    case virtual_host do
      true ->
        case bucket_as_host do
          true -> "#{scheme}#{bucket}#{port}#{object}"
          false -> "#{scheme}#{bucket}.#{host}#{port}#{object}"
        end

      false ->
        "#{scheme}#{host}#{port}/#{bucket}#{object}"
    end
  end

  @excluded_ports [80, "80", 443, "443"]
  defp sanitized_port_component(%{port: nil}), do: ""
  defp sanitized_port_component(%{port: port}) when port in @excluded_ports, do: ""
  defp sanitized_port_component(%{port: port}), do: ":#{port}"
  defp sanitized_port_component(_config), do: ""

  defp ensure_slash("/" <> _rest = path), do: path
  defp ensure_slash(path), do: "/" <> path

  defp validate_config(%{disable_headers_signature: true} = config),
    do: {:ok, config}

  defp validate_config(config) do
    with :ok <- get_key(config, :secret_access_key),
         :ok <- get_key(config, :access_key_id) do
      {:ok, config}
    end
  end

  defp get_key(config, key) do
    case Map.fetch(config, key) do
      :error ->
        {:error, "Required key: #{inspect(key)} not found in config!"}

      {:ok, nil} ->
        {:error, "Required key: #{inspect(key)} is nil in config!"}

      {:ok, val} when is_binary(val) ->
        :ok

      {:ok, val} ->
        {:error, "Required key: #{inspect(key)} must be a string, but instead is #{inspect(val)}"}
    end
  end

  defp service_name(service) do
    Atom.to_string(service)
  end

  defp presigned_url_headers(url, headers) do
    uri = URI.parse(url)
    custom_headers = Application.get_env(:bemeda_personal, :s3_custom_headers, [])
    canonical_headers([{"host", uri.authority} | headers] ++ custom_headers)
  end

  defp canonical_headers(headers) do
    headers
    |> Enum.reduce([], &process_header/2)
    |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 < k2 end)
  end

  defp process_header({k, _value}, acc) when k in @unsignable_headers_multi_case do
    acc
  end

  defp process_header({k, v}, acc) when is_binary(v) do
    k_str = to_string(k)
    k_downcased = String.downcase(k_str)
    v_trimmed = String.trim(v)
    [{k_downcased, v_trimmed} | acc]
  end

  defp process_header({k, v}, acc) do
    k_str = to_string(k)
    k_downcased = String.downcase(k_str)
    [{k_downcased, v} | acc]
  end

  defp query_from_parsed_uri(%{query: nil}), do: []

  defp query_from_parsed_uri(%{query: query_string}) do
    query_string
    |> URI.decode_query()
    |> Enum.to_list()
  end

  defp build_amz_query_params(service, datetime, config, expires, signed_headers) do
    base_params = [
      {"X-Amz-Algorithm", "AWS4-HMAC-SHA256"},
      {"X-Amz-Credential", generate_credential_v4(service, config, datetime)},
      {"X-Amz-Date", amz_date(datetime)},
      {"X-Amz-Expires", expires},
      {"X-Amz-SignedHeaders", signed_headers_value(signed_headers)}
    ]

    if config[:security_token] do
      [{"X-Amz-Security-Token", config[:security_token]} | base_params]
    else
      base_params
    end
  end

  defp signed_headers_value(headers) do
    Enum.map_join(headers, ";", &elem(&1, 0))
  end

  defp amz_date({date, time}) do
    date_fmt = quasi_iso_format(date)
    time_fmt = quasi_iso_format(time)

    IO.iodata_to_binary([date_fmt, "T", time_fmt, "Z"])
  end

  defp quasi_iso_format({y, m, d}) do
    values = [y, m, d]
    int_strings = Enum.map(values, &Integer.to_string/1)
    Enum.map(int_strings, &zero_pad/1)
  end

  defp zero_pad(<<_char>> = val), do: "0" <> val
  defp zero_pad(val), do: val
end
