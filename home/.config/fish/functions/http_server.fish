function http_server -d "Start a simple webserver" -a port;
	set -l port (expr "$port" \| "8000")

	ruby -run -ehttpd . -p "$port"
end
