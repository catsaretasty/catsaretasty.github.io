#!/bin/sh
# Builds the site into the gitignored _site folder in safe mode,
# the same mode GitHub Pages uses. Works from any directory.

# Stop on the first failing command.
set -e

# Repo root is the parent of this script's folder.
root="$(cd "$(dirname "$0")/.." && pwd)"

# Point Bundler at the repo Gemfile, then build with explicit source and destination.
BUNDLE_GEMFILE="$root/Gemfile" bundle exec jekyll build --safe --source "$root" --destination "$root/_site"
