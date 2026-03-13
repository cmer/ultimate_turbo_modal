#!/bin/bash
cd demo-app
rails generate ultimate_turbo_modal:update --flavor=tailwind --force
rails generate ultimate_turbo_modal:update --flavor=vanilla --force

cleanup() {
  if [ -S .overmind.sock ]; then
    overmind quit 2>/dev/null
    sleep 1
    rm -f .overmind.sock
  fi
}

trap cleanup EXIT INT TERM

# Clean up stale socket from a previous unclean shutdown
if [ -S .overmind.sock ]; then
  echo "Cleaning up stale overmind socket..."
  overmind quit 2>/dev/null
  sleep 1
  rm -f .overmind.sock
fi

bin/dev
