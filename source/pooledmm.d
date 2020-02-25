import core.stdc.stdlib, dvector;

// Below is a direct reimplementation of Free Pascal's `TNonFreePooledMemManager` in D,
// which as I suspected it would be is massively faster than attempting to rely on the GC
// for this benchmark.

class TNonFreePooledMemManager(T) if (!(is(T == class) || is(T == interface))) {
private:
  size_t curSize;
  void* curItem, endItem;
  PointerList items;

public:
  this() {
    curSize = T.sizeof * 4;
    items = PointerList.init;
  }

  ~this() {
    clear();
  }

  nothrow @nogc void clear() {
    if (items.length > 0) {
      for (auto i = 0; i < items.length; ++i)
        free(items[i]);
      // Dvector's `free` member function is what other libraries more often call `clear` BTW
      items.free();
    }
    curItem = null;
    endItem = null;
    curSize = T.sizeof * 4;
  }

  nothrow @nogc T* newItem() {
    if (curItem == endItem) {
      curSize += curSize;
      curItem = malloc(curSize);
      items.pushBack(curItem);
      endItem = curItem;
      endItem += curSize;
    }
    void* result = curItem;
    curItem += T.sizeof;
    return cast(T*) result;
  }
}
