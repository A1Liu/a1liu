#!/bin/sh

git checkout main || exit 1
git push || exit 1
git checkout -b production || exit 1

echo '!*.wasm' >> public/.gitignore

zig build -Drelease-small || exit 1
cp zig-out/lib/*.wasm public/assets

git add .
git commit -m "Deployment"

git push -uf origin production
git checkout main
git branch -D production
