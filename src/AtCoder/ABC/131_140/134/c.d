import std.stdio;
import std.string;
import std.format;
import std.conv;
import std.typecons;
import std.algorithm;
import std.functional;
import std.bigint;
import std.numeric;
import std.array;
import std.math;
import std.range;
import std.container;
import std.concurrency;
import std.traits;
import std.uni;
import core.bitop : popcnt;
alias Generator = std.concurrency.Generator;

enum long INF = long.max/5;
enum long MOD = 10L^^9+7;

void main() {
  long N;
  scanln(N);
  long[] as = N.rep!(() => readln.chomp.to!long);
  auto tree = SegTree!(long, (a, b) => max(a, b), -INF)(as);
  foreach(i; 0..N) {
    writeln(max(tree.query(0, i), tree.query(i+1, N)));
  }
}

// // RMQ (Range Minimum Query)
// alias RMQ(T) = SegTree!(T, "a<b ? a:b", T.max);

// SegTree (Segment Tree)
//    - with 1-based array
struct SegTree(T, alias fun, T initValue, bool structly = true)
  if (is(typeof(binaryFun!fun(T.init, T.init)) : T)) {

private:
  alias _fun = binaryFun!fun;
  Pair[] _data;
  size_t _size;
  size_t _l, _r;

public:
  // size ... データ数
  // initValue ... 初期値(例えばRMQだとINF)
  this(size_t size) {
    init(size);
  }

  // 配列で指定
  this(T[] ary) {
    init(ary.length);
    update(ary);
  }

  // O(N)
  void init(size_t size){
    _size = 1;
    while(_size < size) {
      _size *= 2;
    }
    _data.length = _size*2;
    _data[] = Pair(size_t.max, initValue);
    _l = 0;
    _r = size;
  }

  // i番目の要素をxに変更
  // O(logN)
  void update(size_t i, T x) {
    size_t index = i;
    _data[i += _size] = Pair(index, x);
    while(i > 0) {
      i >>= 1;
      Pair nl = _data[i*2+0];
      Pair nr = _data[i*2+1];
      _data[i] = select(nl, nr);
    }
  }

  // 配列で指定
  // O(N)
  void update(T[] ary) {
    foreach(i, e; ary) {
      _data[i+_size] = Pair(i, e);
    }
    foreach_reverse(i; 1.._size) {
      Pair nl = _data[i*2+0];
      Pair nr = _data[i*2+1];
      _data[i] = select(nl, nr);
    }
  }

  // 区間[a, b)でのクエリ (valueの取得)
  // O(logN)
  T query(size_t a, size_t b) {
    Pair pair = accumulate(a, b);
    // Pair pair = queryRec(a, b, 0, 0, _size);
    return pair.value;
  }

  // 区間[a, b)でのクエリ (indexの取得)
  // O(logN)
  size_t queryIndex(size_t a, size_t b) out(result) {
    // fun == (a, b) => a+b のようなときはindexを聞くとassertion
    if (structly) assert(result != size_t.max);
  } body {
    Pair pair = accumulate(a, b);
    // Pair pair = queryRec(a, b, 0, 0, _size);
    return pair.index;
  }

  // 区間[a, b)でのクエリ ((index, value)の取得)
  // O(logN)
  Pair queryPair(size_t a, size_t b) out(result) {
    // fun == (a, b) => a+b のようなときはindexを聞くとassertion
    if (structly) assert(result.index != size_t.max);
  } body {
    Pair pair = accumulate(a, b);
    // Pair pair = queryRec(a, b, 0, 0, _size);
    return pair;
  }

  private Pair accumulate(size_t l, size_t r) {
    if (r<=_l || _r<=l) return Pair(size_t.max, initValue);
    Pair accl = Pair(size_t.max, initValue);
    Pair accr = Pair(size_t.max, initValue);
    for (l += _size, r += _size; l < r; l >>= 1, r >>= 1) {
      if (l&1) accl = select(accl, _data[l++]);
      if (r&1) accr = select(_data[r-1], accr);
    }
    return select(accl, accr);
  }

  // private Pair queryRec(size_t a, size_t b, size_t k, size_t l, size_t r) {
  //   if (b<=l || r<=a) return Pair(size_t.max, initValue);
  //   if (a<=l && r<=b) return _data[k];
  //   size_t c = (l+r)/2;
  //   Pair nl = queryRec(a, b, k*2+0, l, c);
  //   Pair nr = queryRec(a, b, k*2+1, c, r);
  //   return select(nl, nr);
  // }

  private Pair select(Pair nl, Pair nr) {
    T v = _fun(nl.value, nr.value);
    if (nl.value == v) {
      return nl;
    } else if (nr.value == v) {
      return nr;
    } else {
      return Pair(size_t.max, v);
    }
  }

  // O(1)
  T get(size_t i) {
    return _data[_size + i].value;
  }

  // O(N)
  T[] array() {
    return _data[_l+_size.._r+_size].map!"a.value".array;
  }

  struct Pair {
    size_t index;
    T value;
  }
}


// ----------------------------------------------


void times(alias fun)(long n) {
  // n.iota.each!(i => fun());
  foreach(i; 0..n) fun();
}
auto rep(alias fun, T = typeof(fun()))(long n) {
  // return n.iota.map!(i => fun()).array;
  T[] res = new T[n];
  foreach(ref e; res) e = fun();
  return res;
}

T ceil(T)(T x, T y) if (isIntegral!T || is(T == BigInt)) {
  // `(x+y-1)/y` will only work for positive numbers ...
  T t = x / y;
  if (t * y < x) t++;
  return t;
}

T floor(T)(T x, T y) if (isIntegral!T || is(T == BigInt)) {
  T t = x / y;
  if (t * y > x) t--;
  return t;
}

ref T ch(alias fun, T, S...)(ref T lhs, S rhs) {
  return lhs = fun(lhs, rhs);
}
unittest {
  long x = 1000;
  x.ch!min(2000);
  assert(x == 1000);
  x.ch!min(3, 2, 1);
  assert(x == 1);
  x.ch!max(100).ch!min(1000); // clamp
  assert(x == 100);
  x.ch!max(0).ch!min(10); // clamp
  assert(x == 10);
}

mixin template Constructor() {
  import std.traits : FieldNameTuple;
  this(Args...)(Args args) {
    // static foreach(i, v; args) {
    foreach(i, v; args) {
      mixin("this." ~ FieldNameTuple!(typeof(this))[i]) = v;
    }
  }
}

void scanln(Args...)(auto ref Args args) {
  enum sep = " ";
  enum n = Args.length;
  enum fmt = n.rep!(()=>"%s").join(sep) ~ "\n";
  static if (__VERSION__ >= 2071) {
    readf!fmt(args);
  } else {
    enum argsTemp = n.iota.map!(
      i => "&args[%d]".format(i)
    ).join(", ");
    mixin(
      "readf(fmt, " ~ argsTemp ~ ");"
    );
  }
}

// fold was added in D 2.071.0
static if (__VERSION__ < 2071) {
  template fold(fun...) if (fun.length >= 1) {
    auto fold(R, S...)(R r, S seed) {
      static if (S.length < 2) {
        return reduce!fun(seed, r);
      } else {
        return reduce!fun(tuple(seed), r);
      }
    }
  }
}

// cumulativeFold was added in D 2.072.0
static if (__VERSION__ < 2072) {
  template cumulativeFold(fun...)
  if (fun.length >= 1)
  {
    import std.meta : staticMap;
    private alias binfuns = staticMap!(binaryFun, fun);

    auto cumulativeFold(R)(R range)
    if (isInputRange!(Unqual!R))
    {
      return cumulativeFoldImpl(range);
    }

    auto cumulativeFold(R, S)(R range, S seed)
    if (isInputRange!(Unqual!R))
    {
      static if (fun.length == 1)
        return cumulativeFoldImpl(range, seed);
      else
        return cumulativeFoldImpl(range, seed.expand);
    }

    private auto cumulativeFoldImpl(R, Args...)(R range, ref Args args)
    {
      import std.algorithm.internal : algoFormat;

      static assert(Args.length == 0 || Args.length == fun.length,
        algoFormat("Seed %s does not have the correct amount of fields (should be %s)",
          Args.stringof, fun.length));

      static if (args.length)
        alias State = staticMap!(Unqual, Args);
      else
        alias State = staticMap!(ReduceSeedType!(ElementType!R), binfuns);

      foreach (i, f; binfuns)
      {
        static assert(!__traits(compiles, f(args[i], e)) || __traits(compiles,
            { args[i] = f(args[i], e); }()),
          algoFormat("Incompatible function/seed/element: %s/%s/%s",
            fullyQualifiedName!f, Args[i].stringof, E.stringof));
      }

      static struct Result
      {
      private:
        R source;
        State state;

        this(R range, ref Args args)
        {
          source = range;
          if (source.empty)
            return;

          foreach (i, f; binfuns)
          {
            static if (args.length)
              state[i] = f(args[i], source.front);
            else
              state[i] = source.front;
          }
        }

      public:
        @property bool empty()
        {
          return source.empty;
        }

        @property auto front()
        {
          assert(!empty, "Attempting to fetch the front of an empty cumulativeFold.");
          static if (fun.length > 1)
          {
            import std.typecons : tuple;
            return tuple(state);
          }
          else
          {
            return state[0];
          }
        }

        void popFront()
        {
          assert(!empty, "Attempting to popFront an empty cumulativeFold.");
          source.popFront;

          if (source.empty)
            return;

          foreach (i, f; binfuns)
            state[i] = f(state[i], source.front);
        }

        static if (isForwardRange!R)
        {
          @property auto save()
          {
            auto result = this;
            result.source = source.save;
            return result;
          }
        }

        static if (hasLength!R)
        {
          @property size_t length()
          {
            return source.length;
          }
        }
      }

      return Result(range, args);
    }
  }
}

// minElement/maxElement was added in D 2.072.0
static if (__VERSION__ < 2072) {
  private template RebindableOrUnqual(T)
  {
      static if (is(T == class) || is(T == interface) || isDynamicArray!T || isAssociativeArray!T)
          alias RebindableOrUnqual = Rebindable!T;
      else
          alias RebindableOrUnqual = Unqual!T;
  }
  private auto extremum(alias map, alias selector = "a < b", Range)(Range r)
  if (isInputRange!Range && !isInfinite!Range &&
      is(typeof(unaryFun!map(ElementType!(Range).init))))
  in
  {
      assert(!r.empty, "r is an empty range");
  }
  body
  {
      alias Element = ElementType!Range;
      RebindableOrUnqual!Element seed = r.front;
      r.popFront();
      return extremum!(map, selector)(r, seed);
  }

  private auto extremum(alias map, alias selector = "a < b", Range,
                        RangeElementType = ElementType!Range)
                       (Range r, RangeElementType seedElement)
  if (isInputRange!Range && !isInfinite!Range &&
      !is(CommonType!(ElementType!Range, RangeElementType) == void) &&
       is(typeof(unaryFun!map(ElementType!(Range).init))))
  {
      alias mapFun = unaryFun!map;
      alias selectorFun = binaryFun!selector;

      alias Element = ElementType!Range;
      alias CommonElement = CommonType!(Element, RangeElementType);
      RebindableOrUnqual!CommonElement extremeElement = seedElement;


      // if we only have one statement in the loop, it can be optimized a lot better
      static if (__traits(isSame, map, a => a))
      {

          // direct access via a random access range is faster
          static if (isRandomAccessRange!Range)
          {
              foreach (const i; 0 .. r.length)
              {
                  if (selectorFun(r[i], extremeElement))
                  {
                      extremeElement = r[i];
                  }
              }
          }
          else
          {
              while (!r.empty)
              {
                  if (selectorFun(r.front, extremeElement))
                  {
                      extremeElement = r.front;
                  }
                  r.popFront();
              }
          }
      }
      else
      {
          alias MapType = Unqual!(typeof(mapFun(CommonElement.init)));
          MapType extremeElementMapped = mapFun(extremeElement);

          // direct access via a random access range is faster
          static if (isRandomAccessRange!Range)
          {
              foreach (const i; 0 .. r.length)
              {
                  MapType mapElement = mapFun(r[i]);
                  if (selectorFun(mapElement, extremeElementMapped))
                  {
                      extremeElement = r[i];
                      extremeElementMapped = mapElement;
                  }
              }
          }
          else
          {
              while (!r.empty)
              {
                  MapType mapElement = mapFun(r.front);
                  if (selectorFun(mapElement, extremeElementMapped))
                  {
                      extremeElement = r.front;
                      extremeElementMapped = mapElement;
                  }
                  r.popFront();
              }
          }
      }
      return extremeElement;
  }

  private auto extremum(alias selector = "a < b", Range)(Range r)
  if (isInputRange!Range && !isInfinite!Range &&
      !is(typeof(unaryFun!selector(ElementType!(Range).init))))
  {
      return extremum!(a => a, selector)(r);
  }

  // if we only have one statement in the loop it can be optimized a lot better
  private auto extremum(alias selector = "a < b", Range,
                        RangeElementType = ElementType!Range)
                       (Range r, RangeElementType seedElement)
  if (isInputRange!Range && !isInfinite!Range &&
      !is(CommonType!(ElementType!Range, RangeElementType) == void) &&
      !is(typeof(unaryFun!selector(ElementType!(Range).init))))
  {
      return extremum!(a => a, selector)(r, seedElement);
  }

  auto minElement(alias map = (a => a), Range)(Range r)
  if (isInputRange!Range && !isInfinite!Range)
  {
      return extremum!map(r);
  }
  auto minElement(alias map = (a => a), Range, RangeElementType = ElementType!Range)
                 (Range r, RangeElementType seed)
  if (isInputRange!Range && !isInfinite!Range &&
      !is(CommonType!(ElementType!Range, RangeElementType) == void))
  {
      return extremum!map(r, seed);
  }
  auto maxElement(alias map = (a => a), Range)(Range r)
  if (isInputRange!Range && !isInfinite!Range)
  {
      return extremum!(map, "a > b")(r);
  }
  auto maxElement(alias map = (a => a), Range, RangeElementType = ElementType!Range)
                 (Range r, RangeElementType seed)
  if (isInputRange!Range && !isInfinite!Range &&
      !is(CommonType!(ElementType!Range, RangeElementType) == void))
  {
      return extremum!(map, "a > b")(r, seed);
  }
}

// popcnt with ulongs was added in D 2.071.0
static if (__VERSION__ < 2071) {
  ulong popcnt(ulong x) {
    x = (x & 0x5555555555555555L) + (x>> 1 & 0x5555555555555555L);
    x = (x & 0x3333333333333333L) + (x>> 2 & 0x3333333333333333L);
    x = (x & 0x0f0f0f0f0f0f0f0fL) + (x>> 4 & 0x0f0f0f0f0f0f0f0fL);
    x = (x & 0x00ff00ff00ff00ffL) + (x>> 8 & 0x00ff00ff00ff00ffL);
    x = (x & 0x0000ffff0000ffffL) + (x>>16 & 0x0000ffff0000ffffL);
    x = (x & 0x00000000ffffffffL) + (x>>32 & 0x00000000ffffffffL);
    return x;
  }
}
