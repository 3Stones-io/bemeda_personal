defmodule BemedaPersonal.S3Helper.Http do
  @moduledoc false

  @behaviour BemedaPersonal.S3Helper.Client

  @unsignable_headers_multi_case ["x-amzn-trace-id", "X-Amzn-Trace-Id"]
  @one_week 60 * 60 * 24 * 7

  require Logger

  @impl BemedaPersonal.S3Helper.Client
  def get_presigned_url(upload_id, method) do
    config =
      :bemeda_personal
      |> Application.get_env(:s3)
      |> Enum.into(%{})
      |> prepare_s3_config()

    {:ok, url} = presigned_url(config, method, config[:bucket], upload_id)

    url
  end

  defp prepare_s3_config(config) do
    endpoint_url = config[:endpoint_url_s3] || config[:endpoint_url]

    if endpoint_url do
      uri = URI.parse(endpoint_url)

      config
      |> Map.put(:scheme, "#{uri.scheme}://")
      |> Map.put(:host, uri.host)
      |> Map.put_new(:port, uri.port)
    else
      config
    end
  end

  defp presigned_url(config, http_method, bucket, object, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in, 3600)
    query_params = Keyword.get(opts, :query_params, [])
    virtual_host = Keyword.get(opts, :virtual_host, false)
    s3_accelerate = Keyword.get(opts, :s3_accelerate, false)
    bucket_as_host = Keyword.get(opts, :bucket_as_host, false)
    headers = Keyword.get(opts, :headers, [])

    {config, virtual_host} =
      if s3_accelerate,
        do: {put_accelerate_host(config), true},
        else: {config, virtual_host}

    case expires_in > @one_week do
      true ->
        {:error, "expires_in_exceeds_one_week"}

      false ->
        url = url_to_sign(bucket, object, config, virtual_host, bucket_as_host)

        datetime =
          Keyword.get(opts, :start_datetime, NaiveDateTime.utc_now())
          |> case do
            dt when is_struct(dt, DateTime) or is_struct(dt, NaiveDateTime) ->
              NaiveDateTime.to_erl(dt)

            # assume :calendar.datetime()
            dt ->
              dt
          end

        presigned_url(
          http_method,
          url,
          :s3,
          datetime,
          config,
          expires_in,
          query_params,
          nil,
          headers
        )
    end
  end

  defp presigned_url(
         http_method,
         url,
         service,
         datetime,
         config,
         expires,
         query_params,
         body,
         headers
       ) do
    with {:ok, config} <- validate_config(config) do
      service = service_name(service)
      signed_headers = presigned_url_headers(url, headers)

      uri = URI.parse(url)
      uri_query = query_from_parsed_uri(uri)

      org_query_params =
        Enum.reduce(query_params, uri_query, fn {k, v}, acc -> [{to_string(k), v} | acc] end)

      amz_query_params =
        build_amz_query_params(service, datetime, config, expires, signed_headers)

      query_to_sign = (org_query_params ++ amz_query_params) |> canonical_query_params()

      amz_query_string = canonical_query_params(amz_query_params)

      query_for_url =
        if Enum.any?(org_query_params) do
          canonical_query_params(org_query_params) <> "&" <> amz_query_string
        else
          amz_query_string
        end

      path = url |> get_path(service) |> uri_encode()

      signature =
        signature(
          http_method,
          url,
          query_to_sign,
          signed_headers,
          body,
          service,
          datetime,
          config
        )

      {:ok,
       "#{uri.scheme}://#{uri.authority}#{path}?#{query_for_url}&X-Amz-Signature=#{signature}"}
    end
  end

  defp signature(http_method, url, query, headers, body, service, datetime, config) do
    path = url |> get_path(service) |> uri_encode()
    request = build_canonical_request(http_method, path, query, headers, body)
    string_to_sign = string_to_sign(request, service, datetime, config)
    generate_signature_v4(service, config, datetime, string_to_sign)
  end

  defp generate_signature_v4(service, config, datetime, string_to_sign) do
    service
    |> signing_key(datetime, config)
    |> hmac_sha256(string_to_sign)
    |> bytes_to_hex
  end

  defp signing_key(service, datetime, config) do
    ["AWS4", config[:secret_access_key]]
    |> hmac_sha256(date(datetime))
    |> hmac_sha256(config[:region])
    |> hmac_sha256(service)
    |> hmac_sha256("aws4_request")
  end

  defp hash_sha256(data) do
    :sha256
    |> :crypto.hash(data)
    |> bytes_to_hex
  end

  Code.ensure_loaded?(:crypto) || IO.warn(":crypto module failed to load")

  case function_exported?(:crypto, :mac, 4) do
    true ->
      defp hmac_sha256(key, data), do: :crypto.mac(:hmac, :sha256, key, data)

    false ->
      defp hmac_sha256(key, data), do: :crypto.hmac(:sha256, key, data)
  end

  defp date({date, _time}) do
    date |> quasi_iso_format
  end

  defp get_path(url, service \\ nil)

  defp get_path(url, service) when service in ["s3", :s3] do
    base =
      url
      |> URI.parse()
      |> Map.put(:path, nil)
      |> Map.put(:query, nil)
      |> Map.put(:fragment, nil)
      |> URI.to_string()

    [_base, path_with_params] = String.split(url, base, parts: 2)
    [path | _query_params] = String.split(path_with_params, "?", parts: 2)

    path
  end

  defp get_path(url, _), do: URI.parse(url).path || "/"

  defp string_to_sign(request, service, datetime, config) do
    request = hash_sha256(request)

    """
    AWS4-HMAC-SHA256
    #{amz_date(datetime)}
    #{generate_credential_scope_v4(service, config, datetime)}
    #{request}
    """
    |> String.trim_trailing()
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
    bytes
    |> Base.encode16(case: :lower)
  end

  defp build_canonical_request(http_method, path, query, headers, body) do
    http_method = http_method |> method_string |> String.upcase()

    headers = headers |> canonical_headers

    header_string =
      headers
      |> Enum.map(fn {k, v} -> "#{k}:#{remove_dup_spaces(to_string(v))}" end)
      |> Enum.join("\n")

    signed_headers_list = signed_headers_value(headers)

    payload =
      case body do
        nil -> "UNSIGNED-PAYLOAD"
        _ -> hash_sha256(body)
      end

    [
      http_method,
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
    ]
    |> IO.iodata_to_binary()
  end

  defp remove_dup_spaces(str), do: remove_dup_spaces(str, "")
  defp remove_dup_spaces(str, str), do: str

  defp remove_dup_spaces(str, _last),
    do: str |> String.replace("  ", " ") |> remove_dup_spaces(str)

  defp method_string(method) do
    method
    |> Atom.to_string()
    |> String.upcase()
  end

  defp canonical_query_params(params) do
    params
    |> Enum.sort(&compare_query_params/2)
    |> Enum.map_join("&", &pair/1)
  end

  defp pair({k, _}) when is_list(k) do
    raise ArgumentError, "encode_query/1 keys cannot be lists, got: #{inspect(k)}"
  end

  defp pair({_, v}) when is_list(v) do
    raise ArgumentError, "encode_query/1 values cannot be lists, got: #{inspect(v)}"
  end

  defp pair({k, v}) do
    URI.encode_www_form(Kernel.to_string(k)) <> "=" <> aws_encode_www_form(Kernel.to_string(v))
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
  defp compare_query_params({key_1, _}, {key_2, _}), do: key_1 < key_2

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
  defp sanitized_port_component(_), do: ""

  defp ensure_slash("/" <> _ = path), do: path
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

  defp service_name(service), do: service |> Atom.to_string()

  defp presigned_url_headers(url, headers) do
    uri = URI.parse(url)
    custom_headers = Application.get_env(:bemeda_personal, :s3_custom_headers, [])
    canonical_headers([{"host", uri.authority} | headers] ++ custom_headers)
  end

  defp canonical_headers(headers) do
    headers
    |> Enum.reduce([], fn
      {k, _v}, acc when k in @unsignable_headers_multi_case -> acc
      {k, v}, acc when is_binary(v) -> [{String.downcase(to_string(k)), String.trim(v)} | acc]
      {k, v}, acc -> [{String.downcase(to_string(k)), v} | acc]
    end)
    |> Enum.sort(fn {k1, _}, {k2, _} -> k1 < k2 end)
  end

  defp query_from_parsed_uri(%{query: nil}), do: []

  defp query_from_parsed_uri(%{query: query_string}) do
    query_string
    |> URI.decode_query()
    |> Enum.to_list()
  end

  defp build_amz_query_params(service, datetime, config, expires, signed_headers) do
    [
      {"X-Amz-Algorithm", "AWS4-HMAC-SHA256"},
      {"X-Amz-Credential", generate_credential_v4(service, config, datetime)},
      {"X-Amz-Date", amz_date(datetime)},
      {"X-Amz-Expires", expires},
      {"X-Amz-SignedHeaders", signed_headers_value(signed_headers)}
    ] ++
      if config[:security_token] do
        [{"X-Amz-Security-Token", config[:security_token]}]
      else
        []
      end
  end

  defp signed_headers_value(headers) do
    headers
    |> Enum.map(&elem(&1, 0))
    |> Enum.join(";")
  end

  defp amz_date({date, time}) do
    date = date |> quasi_iso_format
    time = time |> quasi_iso_format

    [date, "T", time, "Z"]
    |> IO.iodata_to_binary()
  end

  defp quasi_iso_format({y, m, d}) do
    [y, m, d]
    |> Enum.map(&Integer.to_string/1)
    |> Enum.map(&zero_pad/1)
  end

  defp zero_pad(<<_>> = val), do: "0" <> val
  defp zero_pad(val), do: val
end
