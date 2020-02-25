set -e
dub build --build=release-nobounds
cd ./bin
time ./binarytrees_benchmark 21
