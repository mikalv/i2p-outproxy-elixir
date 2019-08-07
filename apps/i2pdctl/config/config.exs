use Mix.Config



config :i2psam,
  tunnelLength: 1,
  tunnelQuantity: 5,
  tunnelBackupQuantity: 2,
  signatureType: "RedDSA_SHA512_Ed25519",
  tunnelID: "private-outproxy",
  samHost: '127.0.0.1',
  samPort: 7656
