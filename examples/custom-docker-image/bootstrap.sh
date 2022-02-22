#!/bin/sh

function up() {
    until tailscale up --authkey=${TAILSCALE_AUTHKEY} ${TAILSCALE_UP_ARGS}
    do
        sleep 0.1
    done
}

# send this function into the background
up &

exec tailscaled --tun=userspace-networking --state=$TAILSCALE_STATE_PARAMETER_ARN
