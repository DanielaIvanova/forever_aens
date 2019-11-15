import Config

config :forever_aens,
  name: "daniela.chain",
  password: "123456",
  # will try to prolong the name if the difference between current and expiry block is less or equal to this value
  prolong_before: 10,
  # Ex. current height 100 , name's auction expiry height 109, prolong_before= 10 , so we start bidding because there are less than 9 blocks before expiry
  # 5% of increasing of previous bid
  increment: 1.05

config :forever_aens, :client,
  key_store_path: "my_keystore",
  network_id: "ae_uat",
  url: "https://sdk-testnet.aepps.com/v2",
  internal_url: "https://sdk-testnet.aepps.com/v2",
  gas_price: 1_000_000_000,
  auth: []
