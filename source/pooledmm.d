import core.stdc.stdlib, std.traits, dvector;

// Below is a direct reimplementation of Free Pascal's `TNonFreePooledMemManager` in D,
// which as I suspected it would be is massively faster than attempting to rely on the GC
// for this benchmark.

class TNonFreePooledMemManager(T) if (!(is(T == class) || is(T == interface))) {
public:
  alias PointerList = Dvector!(void*);

private:
  size_t curSize;
  void* curItem, endItem;
  PointerList items;

public:
  this() {
    curSize = T.sizeof * 4;
    curItem = null;
    endItem = null;
    items = PointerList.init;
  }

  ~this() {
    clear();
  }

  nothrow @nogc void clear() {
    if (items.length > 0) {
      for (size_t i = 0; i < items.length; ++i) {
        static if(hasElaborateDestructor!(T)) {
          destroy(*(cast(T*) items[i]));
        }
        free(items[i]);
      }
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
    *result = T.init;
    return result;
  }
}
