if command -v keychain 1>/dev/null 2>&1; then
  eval `keychain --dir $KEYCHAIN_DIR --eval --agents ssh id_rsa id_ed25519`
else
  echo "Keychain not installed"
fi
