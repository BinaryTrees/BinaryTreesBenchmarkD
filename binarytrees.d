import core.stdc.stdlib, std.container.array, std.conv, std.parallelism, std.range, std.stdio;

alias Pointer = void*;

alias TFPList = Array!Pointer;

// Below is a direct reimplementation of TNonFreePooledMemManager in D, which as I suspected
// it would be is massively faster than attempting to rely on the GC for this benchmark.

class TNonFreePooledMemManager {
private:
  size_t FItemSize, FCurSize, FFirstSize;
  void *FCurItem, FEndItem;
  TFPList FItems;

public:
  this(const size_t TheItemSize) {
    FItemSize = TheItemSize;
    FFirstSize = FItemSize * 4;
    FCurSize = FFirstSize;
    FItems = TFPList();
  }

  ~this() {
    clear();
    // No point in leaving the next line for the GC to do at some undetermined time...
    destroy(FItems);
  }

  nothrow @nogc @trusted void clear() {
    if (FItems.length > 0) {
      for (size_t i = 0; i < FItems.length; ++i)
        free(FItems[i]);
      FItems.clear();
    }
    FCurItem = null;
    FEndItem = null;
    FCurSize = FItemSize * 4;
  }

  nothrow @nogc @trusted void *newItem() {
    if (FCurItem == FEndItem) {
      FCurSize += FCurSize;
      FCurItem = malloc(FCurSize);
      FItems.insertBack(FCurItem);
      FEndItem = FCurItem;
      FEndItem += FCurSize;
    }
    void *result = FCurItem;
    FCurItem += FItemSize;
    return result;
  }
}

alias TMemPool = TNonFreePooledMemManager;

struct TDataRec {
  ubyte depth;
  int iterations, check;
}

struct TNode {
  TNode *left, right;

  pragma(inline, true) pure nothrow @nogc @trusted static int checkNode(const TNode *node) {
    if (node.right != null && node.left != null)
      return 1 + checkNode(node.right) + checkNode(node.left);
    return 1;
  }

  pragma(inline, true) nothrow @nogc @trusted static TNode *makeTree(const int depth, TMemPool mp) {
    TNode *result = cast(TNode *)mp.newItem();
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
  defaultPoolThreads(8);
  immutable int maxdepth = args.length > 1 ? to !(int)(args[1]) : 10;

  // Create and destroy a tree of depth MaxDepth + 1.
  auto pool = new TMemPool(TNode.sizeof);
  writeln("stretch tree of depth ", maxdepth + 1, "\t check: ",
          TNode.checkNode(TNode.makeTree(maxdepth + 1, pool)));
  pool.clear();

  // Create a "long lived" tree of depth MaxDepth.
  TNode *tree = TNode.makeTree(maxdepth, pool);

  // While the tree stays live, create multiple trees. Local data is stored in the "Data" variable.
  immutable auto highindex = (maxdepth - mindepth) / 2 + 1;
  auto slice = data[0..highindex];
  foreach (i, ref item; taskPool().parallel(slice, 1)) {
    item.depth = cast(ubyte)(mindepth + i * 2);
    item.iterations = 1 << (maxdepth - i * 2);
    item.check = 0;
    auto ipool = new TMemPool(TNode.sizeof);
    for (auto J = 1; J <= item.iterations; ++J) {
      item.check += TNode.checkNode(TNode.makeTree(item.depth, ipool));
      ipool.clear();
    }
    destroy(ipool);
  }

  // Display the results.
  foreach (i, ref item; slice) {
    writeln(item.iterations, "\t trees of depth ", item.depth, "\t check: ", item.check);
  }

  // Check and destroy the long lived tree.
  writeln("long lived tree of depth ", maxdepth, "\t check: ", TNode.checkNode(tree));
  destroy(pool);
}
