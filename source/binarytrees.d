import std.conv, std.parallelism, std.range, std.stdio, pooledmm;

alias TNodePool = TNonFreePooledMemManager!(TNode);

struct TDataRec {
  ubyte depth;
  int iterations, check;
}

struct TNode {
  TNode* left, right;

  pragma(inline, true) pure nothrow @nogc static int checkNode(const TNode* node) {
    if (node.right != null && node.left != null)
      return 1 + checkNode(node.right) + checkNode(node.left);
    return 1;
  }

  pragma(inline, true) nothrow @nogc static TNode* makeTree(const int depth, TNodePool mp) {
    auto result = mp.newItem();
    result.right = null;
    result.left = null;
    if (depth > 0) {
      result.right = makeTree(depth - 1, mp);
      result.left = makeTree(depth - 1, mp);
    }
    return result;
  }
}

static immutable int mindepth = 4;

static TDataRec[9] data;

void main(in string[] args) {
  // Get a local pointer to `stdout` to avoid repeated `makeGlobal()` calls with `writeln`.
  auto io = &stdout();

  immutable auto maxdepth = args.length > 1 ? to !(int)(args[1]) : 10;

  // Create and destroy a tree of depth `maxdepth + 1`.
  auto pool = new TNodePool();
  io.writeln("stretch tree of depth ", maxdepth + 1, "\t check: ",
             TNode.checkNode(TNode.makeTree(maxdepth + 1, pool)));
  pool.clear();

  // Create a "long lived" tree of depth `maxdepth`.
  auto tree = TNode.makeTree(maxdepth, pool);

  // While the tree stays live, create multiple trees. Local data is stored in
  // the `data` variable.
  immutable auto highindex = (maxdepth - mindepth) / 2 + 1;
  auto slice = data[0 .. highindex];
  foreach (i, ref item; taskPool().parallel(slice, 1)) {
    item.depth = cast(ubyte)(mindepth + i * 2);
    item.iterations = 1 << (maxdepth - i * 2);
    item.check = 0;
    auto ipool = new TNodePool();
    for (auto J = 1; J <= item.iterations; ++J) {
      item.check += TNode.checkNode(TNode.makeTree(item.depth, ipool));
      ipool.clear();
    }
  }

  // Display the results.
  foreach (i, ref item; slice) {
    io.writeln(item.iterations, "\t trees of depth ", item.depth, "\t check: ", item.check);
  }

  // Check and destroy the long lived tree.
  io.writeln("long lived tree of depth ", maxdepth, "\t check: ", TNode.checkNode(tree));
  pool.clear();
}
