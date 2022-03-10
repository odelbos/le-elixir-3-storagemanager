defmodule StorageManager do

  def main(args) do
    if args == [] do
      nl()
      IO.puts "Error, you must provide a command !"
      usage()
      System.halt 1
    end

    defs = [
        switches: [url: :string, name: :string],
        aliases: [u: :url, n: :name]
      ]
    {opts, _, _} = OptionParser.parse args, defs

    [cmd | _rest] = args
    case cmd do
      "list" -> cmd_list()
      "add" -> valid_cmd_add opts
      "setup" -> valid_cmd_setup opts
      _ ->
        IO.puts "\nUnknown command\n"
        System.halt 1
    end
  end

  # -----

  defp cmd_list() do
    config = read_config()
    nl()
    for entry <- config, do: IO.puts "#{entry[:name]} : #{entry[:url]}"
    nl()
  end

  # -----

  defp valid_cmd_add(opts) do
    case opts do
      [name: name, url: url] -> cmd_add name, url
      _ ->
        nl()
        IO.puts "Error, missing switches !"
        usage()
    end
  end

  defp cmd_add(name, url) do
    nl()
    IO.puts "Generating keys ..."

    # Generate RSA keys for server communication
    priv_key = :public_key.generate_key {:rsa, 2048, 65537}
    {:RSAPrivateKey, _v, mod, pub_exp, _pe, _p1, _p2, _e1, _e2, _coef, _other} = priv_key
    pub_key = {:RSAPublicKey, mod, pub_exp}

    b64_priv_key = :public_key.der_encode(:RSAPrivateKey, priv_key)
      |> Base.encode64(padding: false)
    b64_pub_key = :public_key.der_encode(:RSAPublicKey, pub_key)
      |> Base.encode64(padding: false)

    storage_key = :crypto.strong_rand_bytes 32

    # Generate AES storage jey and  and encrypt it with the RSA private key
    b64_storage_key = :crypto.strong_rand_bytes 32
      |> Base.decode64!(padding: false)
      |> :public_key.encrypt_private(priv_key)
      |> Base.encode64(padding: false)

    # -----

    # Prepare entry
    entry = %{}
      |> Map.put(:name, name)
      |> Map.put(:url, url)
      |> Map.put(:pub_key, b64_pub_key)
      |> Map.put(:priv_key, b64_priv_key)
      |> Map.put(:storage_key, b64_storage_key)
      # |> Map.put(:storage_key, Base.encode64(storage_key, padding: false))

    # -----

    # Update config
    config = [entry | read_config()]

    # Save new config
    config_file = "./config/config.json"
    json = Jason.encode! config, pretty: true
    File.write! config_file, json

    IO.puts "Config updated."
    nl()
  end

  # -----

  defp valid_cmd_setup(opts) do
    case opts do
      [name: name] -> cmd_setup name
      _ ->
        nl()
        IO.puts "Error, missing switches !"
        usage()
    end
  end

  defp cmd_setup(name) do
    # Get the entry config
    config = read_config()
    entry = search_entry config, name

    # Get RSA private key
    der_priv_key = entry[:priv_key] |> Base.decode64!(padding: false)
    priv_key = :public_key.der_decode :RSAPrivateKey, der_priv_key

    # Encrypt the storage key
    b64_storage_key = entry[:storage_key]
    #   |> Base.decode64!(padding: false)
    #   |> :public_key.encrypt_private(priv_key)
    #   |> Base.encode64(padding: false)

    # -----

    # Prepare data to send to the remote server
    time = :os.system_time(:seconds) + 10
    b64_time = time
      |> Integer.to_string()
      |> Base.encode64(padding: false)

    data = b64_storage_key <> "." <> b64_time

    # Sign data and prepare the payload
    b64_sig = :public_key.sign(data, :sha256, priv_key)
      |> Base.encode64(padding: false)
    payload = data <> "." <> b64_sig

    # -----

    # Send the payload to the server
    t1 = :os.system_time :millisecond
    response = HTTPoison.post(entry[:url], payload, [{"Content-Type", "text/plain"}])
    t2 = :os.system_time :millisecond

    # -----

    # Result
    nl()
    IO.puts "Duration : #{t2 - t1}ms"
    case response do
      {:ok, %HTTPoison.Response{body: body, status_code: status}} ->
        IO.puts "Status : #{status}"
        IO.puts "Body : #{body}"
      _ ->
        IO.puts "Error cannot send request to server"
    end
    nl()
  end

  # -----

  defp read_config() do
    json = File.read! "./config/config.json"
    Jason.decode! json, keys: :atoms
  end

  defp search_entry(config, name) do
    filtered = Enum.filter config, fn(e) -> e[:name] == name end
    case filtered do
      [entry | _rest] -> entry
      _ ->
        nl()
        IO.puts "No entry for : #{name}"
        nl()
        System.halt 0
    end
  end

  # -----

  defp nl(), do: IO.puts ""

  defp usage() do
    nl()
    IO.puts "-----------------------------------------------------"
    IO.puts "Usage"
    IO.puts "-----------------------------------------------------"
    nl()
    IO.puts "Commands:"
    nl()
    IO.puts "  list"
    IO.puts "      List all the entries from config file."
    nl()
    IO.puts "  add"
    IO.puts "      This command will add a new remote CryptoStorage server to the"
    IO.puts "      local configuration."
    IO.puts "      It will generate an RSA keys pair for server comminication."
    IO.puts "      It will generate an AES storage key used to setup the remote server."
    nl()
    IO.puts "      You must provide the following switches : --url, --name."
    nl()
    IO.puts "  setup"
    IO.puts "      This command will setup a remote CryptoStorage server"
    IO.puts "      It will call /setup on the remote server and send the storage key."
    nl()
    IO.puts "      You must provide the following switches : --name."
    nl()
    IO.puts "Samples:"
    IO.puts "  ./storage_manager list"
    IO.puts "  ./storage_manager add --url h.com/setup --name rpi1"
    IO.puts "  ./stroage_manager setup --name rpi1\n"
  end
end
