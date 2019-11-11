import Config

config :forever_aens,
  name: "cgx.chain",
  password: "123456",
  # Ex. current height 100 , name's auction expiry height 109, start_height_bidding= 10 , so we start bidding because there are less than 9 blocks before expiry
  # 5% of increasing of previous bid
  increment: 1.1

config :forever_aens, :client,
  key_store_path: "my_keystore",
  network_id: "ae_uat",
  url: "https://sdk-testnet.aepps.com/v2",
  internal_url: "https://sdk-testnet.aepps.com/v2",
  gas_price: 1_000_000_000,
  auth: []
