[![Build Status](https://travis-ci.com/binarytrees/binarytreesbenchmarkd.svg?branch=master)](https://travis-ci.com/binarytrees/binarytreesbenchmarkd)

A port to D of my [Free Pascal](https://benchmarksgame-team.pages.debian.net/benchmarksgame/program/binarytrees-fpascal-7.html) "Binary Trees" benchmark implementation, initially written as a self-learning exercise.

Recommended command line for building and running this:

```
dub build --build=release-nobounds
cd ./bin
time ./binarytrees_benchmark 21
```
