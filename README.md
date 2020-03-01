[![Build Status](https://travis-ci.com/binarytrees/binarytreesbenchmarkd.svg?branch=master)](https://travis-ci.com/binarytrees/binarytreesbenchmarkd)

Just a port of my [Free Pascal](https://benchmarksgame-team.pages.debian.net/benchmarksgame/program/binarytrees-fpascal-7.html) Binary Trees benchmark implementation to familiarize myself with D a bit more for working on Dexed.

Recommended command line for building and running this:

```
dub build --build=release-nobounds
cd ./bin
time ./binarytrees_benchmark 21
```
