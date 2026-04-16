#!/bin/sh
set -eu

cd "$(dirname "$0")"

"$(dirname "$0")/stop.sh"
"$(dirname "$0")/start.sh"
