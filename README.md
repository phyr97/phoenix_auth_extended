# PhoenixAuthExtended

This project is part of my Master's thesis research on "Investigation of Modern Authentication Methods in Web Applications using the Phoenix Framework". It provides a generator for implementing various authentication methods in Phoenix applications.

## Overview

PhoenixAuthExtended combines multiple authentication approaches into a flexible generator system:

- Password-based authentication (inspired by [phx.gen.auth](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Auth.html))
- Passwordless authentication using WebAuthn/Passkeys (based on [webauthn_components](https://github.com/liveshowy/webauthn_components))
- OAuth2 authentication using [assent](https://github.com/pow-auth/assent)

The project evolved from a prototype that merged all these authentication methods together into a generator built with [igniter](https://github.com/ash-project/igniter) and [igniterjs](https://github.com/ash-project/igniter_js).

## Project Structure

- `main` branch: Current development version
- `result/prototype` branch: Prototype implementation
- `result/generator` branch: Final generator implementation

## Usage

The main generator command follows this pattern:

```bash
mix pax.gen.auth Accounts User [--basic] [--passkey] [--oauth] [options]
```

### Authentication Methods and Options

#### Basic Authentication
Basic authentication supports email or username as identifier:

```bash
mix pax.gen.auth Accounts User --basic --basic-identifier email
# or
mix pax.gen.auth Accounts User --basic --basic-identifier username
```

The `--basic-identifier` option determines the login identifier:
- `email`: Users will log in using their email address (default)
- `username`: Users will log in using a username

#### Passwordless Authentication
```bash
mix pax.gen.auth Accounts User --passkey
```

#### OAuth2 Authentication
OAuth2 authentication requires a provider name:

```bash
mix pax.gen.auth Accounts User --oauth --oauth-provider github
```

The `--oauth-provider` option specifies the OAuth provider (e.g., github, google). For each provider, the following environment variables will be generated:
- `PROVIDER_CLIENT_ID`
- `PROVIDER_CLIENT_SECRET`

### Combining Authentication Methods
You can combine multiple authentication methods in a single command:

```bash
mix pax.gen.auth Accounts User --basic --basic-identifier username --passkey
```

## Installation

> Note: This package is not yet published on [hex.pm](https://hex.pm).

For now, you can install it directly from GitHub:

```elixir
def deps do
  [
    {:phoenix_auth_extended, git: "https://github.com/phyr97/phoenix_auth_extended.git"}
  ]
end
```

### Important Note on WebAuthn Compatibility

Please note that the current version of `webauthn_components` (0.8.0) is not directly compatible with Phoenix LiveView 1.0.0. If you encounter compatibility issues, you can modify the dependency in your `mix.exs` to use a version adapted for LiveView 1.0.0.

## Future Development

While this project originated as part of my Master's thesis, i want to develop the generator further. The thesis work has established a solid foundation for future enhancements and improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

