#!/usr/bin/env bash

# Miscellaneous aliases

# mdbook build and serve with automatic port cleanup
alias mdbook-serve="fuser -k 3000/tcp 2>/dev/null; mdbook build && mdbook serve"
