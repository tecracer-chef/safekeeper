# safekeeper

## Summary

Interface to talk to different secret managing backends.

Creates an extensible API to access secrets in a unified fashion.

## Usage

```ruby
require "safekeeper"

# Connect to a secret provider
safekeeper = Safekeeper.create("hashicorp-vault", {
  endpoint: "https://vault:8443",

  engine:   "secret",
  type:     "kv2",
  base:     "/prefix/"
  token:    ENV["VAULT_TOKEN"]
})

# List subkeys under /secret/prefix/servers
servers = safekeeper.list("/servers")

# Get document at /secret/prefix/servers/SERVERNAME
document = safekeeper.get("/servers/#{servers.first}")

# Create new document at /secret/prefix/servers/newserver
document = safekeeper.put("/servers/newserver",
  {
    "name": "newname12",
    "ip": "10.20.30.40"
  }
)

# Modify existing document at /secret/prefix/servers/newserver
document = safekeeper.patch("/servers/newserver",
  {
    "name": "newserver12"
  }
)

# Remove document at /secret/prefix/servers/SERVERNAME
safekeeper.delete("/servers/#{servers.first}")

# You can get the raw, provider-specific backend for complex tasks
raw_backend = safekeeper.raw_backend
```

## Core Backends

### Memory

Simple backend for managing data in memory only, without encryption. Mostly
for testing.

```ruby
safekeeper = Safekeeper.create("memory")

safekeeper.put("my-secret", "data-goes-here")

# You can also specify an expiry for this data (in seconds)
safekeeper.put("my-secret", "data-goes-here", ttl: 3600)

safekeeper.get("my-secret")
```

### Hashicorp Vault (Read-only)

```ruby
safekeeper = Safekeeper.create("hashicorp-vault", {
  endpoint: "https://vault:8443",
  token: "abcdefghijklmnopqrstuvwyxz"
})
```

For more low-level options, please look at the [Hashicorp Vault Gem](https://github.com/hashicorp/vault-ruby)

### AWS Secrets Manager (Read-only)

```ruby
safekeeper = Safekeeper.create("aws-secretsmanager", {
  endpoint: "eu-west-1"
})
```

For more low-level options, please read the [AWS Ruby SDK documentation](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SecretsManager/Client.html#initialize-instance_method)

## Integrations

By loading the Gem from within Chef, three new DSL helpers become available:

```ruby
connect_safekeeper("hashicorp-vault", { ... })

data = JSON.parse get_secret("name/of/secret")
subkeys = list_secret_by_prefix("/servers/")
```

You can also use multiple backends in parallel:

```ruby
connect_safekeeper("memory")
connect_safekeeper("hashicorp-vault", { ... })

data = JSON.parse get_secret("name/of/secret", "hashicorp-vault")
users = list_secret_by_prefix("server-users", "memory")
```

## Acknowledgements

This library is modelled after the [Train Gem](https://github.com/inspec/train),
which provides a similar interface for remote system access. Some parts like the
plugin management are close to being a 1:1 copy. Thanks to the Train team for
providing such an easy base to work from
