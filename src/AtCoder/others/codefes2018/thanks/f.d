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

enum long INF = long.max/3;
enum long MOD = 10L^^9+7;

void main() {
  long N, M, K;
  scanln(N, M, K);
  long[] ps = readln.split.to!(long[]).map!"a-1".array;

  Vertex root;
  Vertex[] vs = N.iota.map!(i => new Vertex(i)).array;
  foreach(i, p; ps) {
    if (p<0) {
      root = vs[i];
    } else {
      vs[i].parent = vs[p];
      vs[p].children ~= vs[i];
    }
  }
  assert(root !is null);

  void calcDepth(Vertex v, long depth) {
    v.depth = depth;
    foreach(u; v.children) {
      calcDepth(u, depth + 1);
    }
  }
  calcDepth(root, 0);

  long[] f(Vertex v, Vertex u, ref long sumNum) {
    if (v.used) return [];
    if (v is u) return [];
    long[] res = [v.depth + 1];
    sumNum++;
    if (v !is u) {
      foreach(w; v.children) {
        res ~= f(w, u, sumNum);
      }
    }
    return res;
  }

  void g(Vertex v, bool used) {
    v.used |= used;
    foreach(u; v.children) {
      g(u, v.used);
    }
  }

  long[] ans = [];
  long rest = K;
  foreach(i; 0..M) {
    foreach(v; vs) {
      if (v.used) continue;
      if (rest - v.depth - 1 < 0) continue;
      long num = 0;
      long[] ds = f(root, v, num);
      ds.sort!"a>b";
      if (num < M - i - 1) continue;
      long maxD = ds[0..M-i-1].sum;
      long minD = ds[$-(M-i-1)..$].sum;
      if (rest-v.depth-1 >= minD && rest-v.depth-1 <= maxD) {
        ans ~= v.index;
        rest -= v.depth + 1;
        v.used = true;
        g(root, false);
        break;
      }
    }
  }

  if (ans.length == M) {
    ans.map!"a+1".map!(to!string).join(" ").writeln;
  } else {
    writeln(-1);
  }
}

class Vertex {
  long index;
  Vertex parent;
  Vertex[] children;
  long depth;
  bool used = false;
  this(long index) {
    this.index = index;
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
  import std.meta;
  template getFormat(T) {
    static if (isIntegral!T) {
      enum getFormat = "%d";
    } else static if (isFloatingPoint!T) {
      enum getFormat = "%g";
    } else static if (isSomeString!T || isSomeChar!T) {
      enum getFormat = "%s";
    } else {
      static assert(false);
    }
  }
  enum string fmt = [staticMap!(getFormat, Args)].join(" ");
  string[] inputs = readln.chomp.split;
  foreach(i, ref v; args) {
    v = inputs[i].to!(Args[i]);
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
    Unqual!Element seed = r.front;
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
    Unqual!CommonElement extremeElement = seedElement;

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
    return extremeElement;
  }
  private auto extremum(alias selector = "a < b", Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range &&
      !is(typeof(unaryFun!selector(ElementType!(Range).init))))
  {
    alias Element = ElementType!Range;
    Unqual!Element seed = r.front;
    r.popFront();
    return extremum!selector(r, seed);
  }
  private auto extremum(alias selector = "a < b", Range,
              RangeElementType = ElementType!Range)
             (Range r, RangeElementType seedElement)
    if (isInputRange!Range && !isInfinite!Range &&
      !is(CommonType!(ElementType!Range, RangeElementType) == void) &&
      !is(typeof(unaryFun!selector(ElementType!(Range).init))))
  {
    alias Element = ElementType!Range;
    alias CommonElement = CommonType!(Element, RangeElementType);
    Unqual!CommonElement extremeElement = seedElement;
    alias selectorFun = binaryFun!selector;

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
    return extremeElement;
  }
  auto minElement(Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
  {
    return extremum(r);
  }
  auto minElement(alias map, Range, RangeElementType = ElementType!Range)
           (Range r, RangeElementType seed)
  if (isInputRange!Range && !isInfinite!Range &&
    !is(CommonType!(ElementType!Range, RangeElementType) == void))
  {
    return extremum!map(r, seed);
  }
  auto minElement(Range, RangeElementType = ElementType!Range)
           (Range r, RangeElementType seed)
    if (isInputRange!Range && !isInfinite!Range &&
      !is(CommonType!(ElementType!Range, RangeElementType) == void))
  {
    return extremum(r, seed);
  }
  auto maxElement(alias map, Range)(Range r)
  if (isInputRange!Range && !isInfinite!Range)
  {
    return extremum!(map, "a > b")(r);
  }
  auto maxElement(Range)(Range r)
  if (isInputRange!Range && !isInfinite!Range)
  {
    return extremum!`a > b`(r);
  }
  auto maxElement(alias map, Range, RangeElementType = ElementType!Range)
           (Range r, RangeElementType seed)
  if (isInputRange!Range && !isInfinite!Range &&
    !is(CommonType!(ElementType!Range, RangeElementType) == void))
  {
    return extremum!(map, "a > b")(r, seed);
  }
  auto maxElement(Range, RangeElementType = ElementType!Range)
           (Range r, RangeElementType seed)
  if (isInputRange!Range && !isInfinite!Range &&
    !is(CommonType!(ElementType!Range, RangeElementType) == void))
  {
    return extremum!`a > b`(r, seed);
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
