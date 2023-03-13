function FindProxyForURL(url, host) {
  // Check if destination host has a valid IPv6 address
  if (isInNet(dnsResolve(host), "::", "::ffff:ffff:ffff:ffff")) {
    // Use SOCKS5 proxy if host has IPv6 address
    return "SOCKS5 localhost:9952";
  } else {
    // Bypass proxy if host does not have IPv6 address
    return "DIRECT";
  }
}
