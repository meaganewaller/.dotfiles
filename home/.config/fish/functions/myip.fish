function myip --description "Show local and external IP addresses"
  # Local interfaces
  set interfaces (ip -4 -j address | jq -r '.[] | select(.addr_info | length > 0) | .ifname')

  for interface in $interfaces
    set addr (ip -4 -j address show $interface | jq -r '.[0].addr_info[]? | select(.family == "inet") | .local')
    if test -n "$addr"
      echo (set_color blue)$interface:(set_color normal)
      echo "  $addr"
    end
  end

  # External IP
  echo (set_color blue)EXTERNAL:(set_color normal)
  set ipv4 (curl -4 -s https://ifconfig.co 2>/dev/null)
  set ipv6 (curl -6 -s https://ifconfig.co 2>/dev/null)

  if test -n "$ipv4"
    echo "  $ipv4"
  end
  if test -n "$ipv6"
    echo "  $ipv6"
  end
end
