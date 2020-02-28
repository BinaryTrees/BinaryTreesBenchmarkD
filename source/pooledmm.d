// Original author: Akira1364
// Year: 2020
// License: MIT

import core.stdc.stdlib, core.stdc.string, std.traits, dvector;

// Below is a direct reimplementation of Free Pascal's `TNonFreePooledMemManager` in D,
// which as I suspected it would be is massively faster than attempting to rely on the GC
// for this benchmark.

// Basically what I'm trying to do with the static checks here is ensure that `T` can safely be allocated
// with `malloc`, zeroed with `memset`, and deallocated with `free`. If there's a better way to do it than
// what I have at the moment, please feel free to open a PR to change it to whatever that may be!
struct TNonFreePooledMemManager(T, const size_t initialSize = 32) if (!(is(T == class) || 
                                                                        is(T == interface))) {
  static assert(!hasElaborateDestructor!(T));
  static foreach (field; Fields!T) {
    static assert(!(is(field == class) || 
                    is(field == interface)));
  }
private:
  size_t curSize = T.sizeof * initialSize;
  void* curItem, endItem;
  Dvector!(void*) items;

public:
  @disable this(this);

  pragma(inline, true) nothrow @nogc ~this() {
    clear();
  }

  pragma(inline, true) nothrow @nogc void clear() {
    if (items.length > 0) {
      for (size_t i = 0; i < items.length; ++i)
        free(items[i]);
      // Dvector's `free` member function is what other libraries more often call `clear`, BTW.
      items.free();
    }
    curSize = T.sizeof * initialSize;
    curItem = null;
    endItem = null;
  }

  pragma(inline, true) nothrow @nogc T* newItem() {
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
  
  alias TEnumItemsProc = nothrow @nogc void delegate(T* p);

  // Note that this enumerates *all allocated* items, i.e. a number
  // which is always greater than both `items.length` and the number
  // of times that `newItem()` has been called.
  pragma(inline, true) nothrow @nogc void enumerateItems(const TEnumItemsProc proc) {
    if (items.length > 0) {
      immutable auto count = items.length;
      auto size = T.sizeof * initialSize;
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
