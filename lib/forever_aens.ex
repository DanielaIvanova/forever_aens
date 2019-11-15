defmodule ForeverAens do
  @moduledoc """
  Documentation for ForeverAens.
  """
  alias AeppSDK.{Account, AENS, Chain, Client, Middleware}
  alias AeppSDK.Utils.Keys

  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def init(%{}) do
    client = build_client()
    name = Application.get_env(:forever_aens, :name)
    schedule_work()
    {:ok, %{client: client, name: name, claim_height: 0}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:work, state) do
    new_state = extend_name(state)
    schedule_work()

    {:noreply, new_state}
  end

  defp extend_name(
         %{
           client: %Client{keypair: %{public: public}} = client,
           name: name,
           claim_height: claim_height
         } = state
       )
       when is_binary(name) do
    {:ok, height} = Chain.height(client)
    {:ok, active_auctions} = Middleware.get_active_name_auctions(client)

    case Enum.find(active_auctions, :not_active, fn map -> map.name === name end) do
      :not_active ->
        case Middleware.search_name(client, name) do
          {:ok, list} ->
            if Enum.any?(list, fn map -> map.name === name end) do
              state
            else
              case claim_height do
                0 ->
                  client
                  |> AENS.preclaim(name)
                  |> AENS.claim()

                  Logger.info(fn ->
                    "Name was not found, preclaimin' & claimin' in progress...."
                  end)

                  %{state | claim_height: height}

                _ when claim_height == height ->
                  Logger.info(fn ->
                    "Claiming is still in progress...."
                  end)

                  state

                _ when claim_height < height ->
                  Logger.info(fn ->
                    "Name should be claimed now....Starting monitoring for name: #{inspect(name)}"
                  end)

                  state
              end
            end

          {:error, rsn} ->
            Logger.error(fn -> "Could not connect to mdw, reason: #{rsn}" end)
            state
        end

      %{
        name: ^name,
        winning_bid: winning_bid,
        winning_bidder: ^public,
        expiration: _expiration
      } ->
        Logger.info(
          "Auction is still open, but current client: #{public} has already the highest bid: #{
            winning_bid
          } "
        )

        # As we are staying as winner, no actions required
        state

      %{
        name: ^name,
        winning_bid: winning_bid,
        winning_bidder: winning_bidder,
        expiration: expiration
      } ->
        if height <= expiration - Application.get_env(:forever_aens, :prolong_before) do
          {:ok, %{balance: current_balance}} = Account.get(client, public)
          increment = Application.get_env(:forever_aens, :increment, 1.05)
          new_bid = round(String.to_integer(winning_bid) * increment)

          if current_balance < new_bid do
            Logger.error(
              "Insufficient funds: needed: #{new_bid}, but account has only: #{current_balance}"
            )

            state
          else
            AENS.claim(client, name, 0, name_fee: new_bid)
            Logger.info("Successfully placed our new bid: #{inspect(new_bid)}")
            state
          end
        else
          Logger.error(
            "Name is no longer claimable, as it was already claimed by: #{winning_bidder}, trying to reinitialize the server with new state"
          )

          state
        end
    end
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 5_000)
  end

  defp build_client() do
    client_configuration = Application.get_env(:forever_aens, :client)
    password = Application.get_env(:forever_aens, :password)

    secret_key =
      client_configuration
      |> Keyword.get(:key_store_path)
      |> Keys.read_keystore(password)

    network_id = Keyword.get(client_configuration, :network_id)
    url = Keyword.get(client_configuration, :url)
    internal_url = Keyword.get(client_configuration, :internal_url)
    gas_price = Keyword.get(client_configuration, :gas_price)
    public_key = Keys.get_pubkey_from_secret_key(secret_key)
    key_pair = %{public: public_key, secret: secret_key}
    Client.new(key_pair, network_id, url, internal_url, gas_price: gas_price)
  end
end
