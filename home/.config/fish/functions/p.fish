function p --description "List open ports with CSV output"
  begin
    echo "Port"(printf '\x1e')"Protocol"(printf '\x1e')"PID"(printf '\x1e')"Process"(printf '\x1e')"Command"
    ss -tulpn 2>/dev/null | tail -n +2 | awk -v sep=(printf '\x1e') '{
      # ss output: Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
      # Extract protocol (tcp/udp), port, and process info
      protocol = tolower($1)
      if (protocol ~ /tcp/) protocol = "TCP"
      else if (protocol ~ /udp/) protocol = "UDP"

      # Extract port from Local Address:Port
      local_addr = $5
      split(local_addr, addr_parts, ":")
      port = addr_parts[length(addr_parts)]

      # Extract PID and process name from Process field
      # Format: users:(("processname",pid=NNNN,fd=X))
      process = $7
      pid = "-"
      name = "-"

      if (match(process, /"([^"]+)"/, name_match)) {
        name = name_match[1]
      }
      if (match(process, /pid=([0-9]+)/, pid_match)) {
        pid = pid_match[1]
      }

      # Get full command from /proc/[pid]/cmdline
      cmd = "-"
      if (pid != "-") {
        cmd_file = "/proc/" pid "/cmdline"
        if ((getline cmd < cmd_file) > 0) {
          gsub(/\0/, " ", cmd)  # Replace null bytes with spaces
        } else {
          cmd = "-"
        }
        close(cmd_file)
      }

      print port sep protocol sep pid sep name sep cmd
    }'
  end | tw --separator (printf '\x1e') --quote-char (printf '\x1f')
end
