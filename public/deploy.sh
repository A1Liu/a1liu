git checkout main
git branch -D production || true
git checkout -b production
git checkout production

echo '!*.wasm' >> public/.gitignore

zig build -Drelease-small || exit 1
cp zig-out/lib/*.wasm public/assets

git push -uf origin production
