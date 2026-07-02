#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$source_dir/build"
build_info="$build_dir/meson-info/meson-info.json"

cd "$source_dir"

if [[ -f "$build_info" ]] && ! grep -q "\"source_dir\": \"$source_dir\"" "$build_info"; then
  echo "Build directory points somewhere else. Recreating it."
  rm -rf "$build_dir"
fi

if [[ ! -f "$build_dir/build.ninja" ]]; then
  meson setup "$build_dir" --prefix=/usr/local
else
  meson setup "$build_dir" --prefix=/usr/local --reconfigure
fi

meson compile -C build
./build/src/purrify
