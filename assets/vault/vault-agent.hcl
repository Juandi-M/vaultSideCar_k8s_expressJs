pid_file = "/vault-agent.pidfile"

exit_after_auth = true

auto_auth {
  method {
    type = "token_file"
    config = {
      token_file_path = "/etc/vault.d/.vault-token"
    }
  }

  sink  {
    type = "file"
    config = {
      path = "/etc/vault.d/token"
      remove_after_use = true
    }
  }
}

api_proxy {
  use_auto_auth_token = true
}

# appconfigs

template {
  source      = "/etc/vault.d/appconfigs.ctmpl"
  destination = "/home/vault/appconfigs.json"
  error_on_missing_key = true
}

listener "tcp" {
  address     = "127.0.0.1:8100"
  tls_disable = true
}