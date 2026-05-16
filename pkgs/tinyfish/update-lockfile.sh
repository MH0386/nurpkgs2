#!/usr/bin/env bash
set -euo pipefail

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "error: expected to run inside the nurpkgs repository" >&2
  exit 1
fi
package_dir="$repo_root/pkgs/tinyfish"

if [[ ! -f "$package_dir/default.nix" ]]; then
  echo "error: expected to run inside the nurpkgs repository" >&2
  exit 1
fi

version="$(awk -F'"' '/^[[:space:]]*version = "/ { print $2; exit }' "$package_dir/default.nix")"
if [[ -z "$version" ]]; then
  echo "error: could not read tinyfish version from $package_dir/default.nix" >&2
  exit 1
fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Generating package-lock.json for @tiny-fish/cli@$version"

tgz="$(npm pack --silent "@tiny-fish/cli@$version" --pack-destination "$tmp")"
tar -xzf "$tmp/$tgz" -C "$tmp"
published_at="$(
  npm view "@tiny-fish/cli@$version" time --json \
    | node -e '
        const version = process.argv[1];
        let input = "";
        process.stdin.on("data", chunk => input += chunk);
        process.stdin.on("end", () => {
          const time = JSON.parse(input)[version];
          if (time) {
            console.log(time);
          }
        });
      ' "$version"
)"
if [[ -z "$published_at" ]]; then
  echo "error: could not read publish time for @tiny-fish/cli@$version" >&2
  exit 1
fi

pushd "$tmp/package" >/dev/null
npm install \
  --package-lock-only \
  --ignore-scripts \
  --no-audit \
  --no-fund \
  --before "$published_at"
popd >/dev/null

cp "$tmp/package/package-lock.json" "$package_dir/package-lock.json"

echo "Updated $package_dir/package-lock.json"
