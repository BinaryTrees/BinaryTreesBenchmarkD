import core.stdc.stdlib, core.stdc.string, std.traits, dvector;

// Below is a direct reimplementation of Free Pascal's `TNonFreePooledMemManager` in D,
// which as I suspected it would be is massively faster than attempting to rely on the GC
// for this benchmark.

// Luckily, D's rules with regards to arithmetic on untyped pointers are identical to Free
// Pascal's rules with regards to it (as opposed to something like C++'s rules where this
// just wouldn't work without a bunch of changes) so I was able to do a pretty one-to-one
// translation of the original code.

class TNonFreePooledMemManager(T) if (!(is(T == class) || is(T == interface))) {
  static assert(!hasElaborateDestructor!(T));
  static foreach (field; Fields!T) {
    static assert(!(is(field == class) || is(field == interface)));
  }
public:
  alias TPointerList = Dvector!(void*);
  alias TEnumItemsProc = void delegate(T* p);

private:
  size_t curSize;
  void* curItem, endItem;
  TPointerList items;

public:
  this() {
    curSize = T.sizeof * 4;
    curItem = null;
    endItem = null;
    items = TPointerList.init;
  }

  ~this() {
    clear();
  }

  nothrow @nogc void clear() {
    if (items.length > 0) {
      for (size_t i = 0; i < items.length; ++i)
        free(items[i]);
      // Dvector's `free` member function is what other libraries more often call `clear`, BTW.
      items.free();
    }
    curSize = T.sizeof * 4;
    curItem = null;
    endItem = null;
  }

  nothrow @nogc T* newItem() {
    if (curItem == endItem) {
      curSize += curSize;
      curItem = malloc(curSize);
      items.pushBack(curItem);
      endItem = curItem;
      endItem += curSize;
    }
    T* result = cast(T*) curItem;
    curItem += T.sizeof;
    memset(result, 0, T.sizeof);
    return result;
  }

  void enumerateItems(const TEnumItemsProc proc) {
    if (items.length > 0) {
      immutable auto count = items.length;
      auto size = T.sizeof * 4;
      for (size_t i = 0; i < count; ++i) {
        size += size;
        auto p = items[i];
        auto last = p;
        last += size;
        if (i == count - 1)
          last = endItem;
        while (p != last) {
          proc(cast(T*) p);
          p += T.sizeof;
        }
      }
    }
  }
}
