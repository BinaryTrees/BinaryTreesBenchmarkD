// This is the most optimal setting I could find for this benchmark.
extern(C) __gshared string[] rt_options = [
  "gcopt=minPoolSize:256 maxPoolSize:384 cleanup:finalize"
];

import std.conv, std.parallelism, std.range, std.stdio;

struct TDataRec {
  ubyte depth;
  int iterations, check;
}

struct TNode {
  TNode *left, right;

  pragma(inline, true)
  pure nothrow @nogc @trusted static int checkNode(const TNode *node) {
    if (node.right != null && node.left != null)
      return 1 + checkNode(node.right) + checkNode(node.left);
    return 1;
  }

  pragma(inline, true)
  pure nothrow @trusted static TNode *makeTree(const int depth) {
    TNode *result = new TNode();
    if (depth > 0) {
      result.right = makeTree(depth - 1);
      result.left = makeTree(depth - 1);
    }
    return result;
  }
}

static immutable int mindepth = 4;
static TDataRec[9] data;

void main(in string[] args) {
  defaultPoolThreads(8);
  immutable int maxdepth = args.length > 1 ? to !(int)(args[1]) : 10;
  writeln("stretch tree of depth ", maxdepth + 1, "\t check: ",
          TNode.checkNode(TNode.makeTree(maxdepth + 1)));
  TNode *tree = TNode.makeTree(maxdepth);
  immutable auto highindex = (maxdepth - mindepth) / 2 + 1;
  auto slice = data[0..highindex];
  foreach (i, ref item; taskPool.parallel(slice)) {
    item.depth = cast(ubyte)(mindepth + i * 2);
    item.iterations = 1 << (maxdepth - i * 2);
    item.check = 0;
    for (auto J = 1; J <= item.iterations; ++J) {
      item.check += TNode.checkNode(TNode.makeTree(item.depth));
    }
  }
  foreach (i, ref item; slice) {
    writeln(item.iterations, "\t trees of depth ", item.depth, "\t check: ",
            item.check);
  }
  writeln("long lived tree of depth ", maxdepth, "\t check: ",
          TNode.checkNode(tree));
}