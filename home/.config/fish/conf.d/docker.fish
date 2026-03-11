set -l colima_socket "$HOME/.colima/docker.sock"

if test -S "$colima_socket"
	set -Ux DOCKER_HOST "unix://$colima_socket"
	set -Ux TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE /var/run/docker.sock
else
	set -e DOCKER_HOST
	set -e TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE
end
