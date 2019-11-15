# ForeverAENS

Automatic bidding for Aeternity names and auto-renewal.

## Description
`ForeverAENS` is a small showcase prototype project, which is built in Elixir, by using [Aeternity Elixir SDK](https://github.com/aeternity/aepp-sdk-elixir). This application automates all the activities, needed to "hold" a name in [Aeternity blockchain](https://github.com/aeternity/aeternity), this app allows a user to:
1. Preclaim and claim a given name(if the name wasn't found in the blockchain and there is no current auction for it).
2. Prolonging given name before the expiry by user defined number blocks. 
3. Monitor and automatically bid for a given name(if the name's auction is active and if the user has enough tokens for making a new bid).

## Usage
1. Clone the project and get the dependencies:
```
git clone https://github.com/DanielaIvanova/forever_aens
cd forever_aens
mix deps.get
```

2. Now you have to start the elixir app:
```
iex -S mix
```

3. Create your own keypair(if you don't have already one):
``` elixir
%{public: public_key, secret: secret_key} = AeppSDK.Utils.Keys.generate_keypair
```

4. Store your private key in the keystore:
``` elixir
AeppSDK.Utils.Keys.new_keystore(secret_key, "123456", name: "my_keystore")
```

5. Set `config.exs` file, by providing your information. This is an example of `config.exs`:

``` elixir
import Config

config :forever_aens,
  name: "daniela.chain",  # desired name
  password: "123456", # keystore password
  prolong_before: 10  # will try to prolong the name if the difference between current and expiry block is less or equal to this value 
  # Ex. current height 100 , name's auction expiry height 109, prolong_before = 10 , so we start bidding because there are less than 9 blocks before expiry
  # 5% of increasing of previous bid
  increment: 1.05

config :forever_aens, :client,
  key_store_path: "my_keystore",
  network_id: "ae_uat",
  url: "https://sdk-testnet.aepps.com/v2",
  internal_url: "https://sdk-testnet.aepps.com/v2",
  gas_price: 1_000_000_000,
  auth: []
```
6. Now you are ready to start the application:
``` elixir
ForeverAens.start_link
```
**NOTE:** The application will automatically check name status and take actions each **5 seconds**.