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
  long N, M;
  scanln(N, M);
  long[] as = readln.split.to!(long[]);
  long[] bs = readln.split.to!(long[]);
  ModNum[][] dp = new ModNum[][](N+1, M+1);
  foreach(i; 1..N+1) foreach(j; 1..M+1) {
    if (as[i-1] == bs[j-1]) {
      dp[i][j] = 1 + dp[i][j-1] + dp[i-1][j];
    } else {
      dp[i][j] = dp[i][j-1] + dp[i-1][j] - dp[i-1][j-1];
    }
  }
  writeln(dp[N][M] + 1);
}

alias ModNum = ModNumber!(long, MOD);

struct ModNumber(T, T mod) if (__traits(isIntegral, T)) {
  private enum FACT_MAX = 1000010;

  T value;
  this(T value) {
    this.value = value;
    this.value %= mod;
    this.value += mod;
    this.value %= mod;
  }

  ModNumber opAssign(T value) {
    this.value = value;
    return this;
  }

  ModNumber opBinary(string op)(ModNumber that) if (op=="+" || op=="-" || op=="*") {
    return ModNumber(mixin("(this.value "~op~" that.value + mod) % mod"));
  }
  ModNumber opBinary(string op)(T that) if (op=="+" || op=="-" || op=="*") {
    return ModNumber(mixin("(this.value "~op~" that + mod) % mod"));
  }
  ModNumber opBinaryRight(string op)(T that) if (op=="+" || op=="-" || op=="*") {
    return ModNumber(mixin("(that "~op~" this.value + mod) % mod"));
  }

  ModNumber opBinary(string op)(ModNumber that) if (op == "/") {
    return this*getReciprocal(that);
  }
  ModNumber opBinary(string op)(T that) if (op == "/") {
    return this*getReciprocal(ModNumber(that));
  }
  ModNumber opBinaryRight(string op)(T that) if (op == "/") {
    return ModNumber(that)*getReciprocal(this);
  }

  ModNumber opBinary(string op)(ModNumber that) if (op == "^^") {
    return ModNumber(modPow(this.value, that.value));
  }
  ModNumber opBinary(string op)(T that) if (op == "^^") {
    return ModNumber(modPow(this.value, that));
  }
  ModNumber opBinaryRight(string op)(T that) if (op == "^^") {
    return ModNumber(modPow(that, this.value));
  }

  void opOpAssign(string op)(ModNumber that) if (op=="+" || op=="-" || op=="*" || op=="/") {
    this = mixin("this" ~op~ "that");
  }
  void opOpAssign(string op)(T that) if (op=="+" || op=="-" || op=="*" || op=="/") {
    this = mixin("this" ~op~ "that");
  }

  ModNumber getReciprocal(ModNumber x) in {
    debug assert(isPrime(mod));
  } body {
    return ModNumber(modPow(x.value, mod-2));
  }
  T modPow(T base, T power)  {
    T result = 1;
    for (; power > 0; power >>= 1) {
      if (power & 1) {
        result = (result * base) % mod;
      }
      base = base*base % mod;
    }
    return result;
  }

  static bool isPrime(T n) {
    if (n<2) {
      return false;
    } else if (n==2) {
      return true;
    } else if (n%2==0) {
      return false;
    } else {
      for(T i=3; i*i<=n; i+=2) {
        if (n%i==0) return false;
      }
      return true;
    }
  }

  // n! : 階乗
  static ModNumber fact(T n) {
    assert(0<=n && n<=FACT_MAX);
    static ModNumber[] memo;
    if (memo.length == 0) {
      memo = new ModNumber[FACT_MAX+1];
      memo[0] = ModNumber(1);
      assert(memo[0] != ModNumber.init);
    }
    auto acc = ModNumber(1);
    foreach_reverse(i; 0..n+1) {
      if (memo[i] != ModNumber.init) {
        foreach(j; i+1..n+1) {
          memo[j] = memo[j-1] * j;
        }
        return memo[n];
      }
    }
    assert(false);
  }

  // 1/(n!) : 階乗の逆元 (逆元テーブルを用いる)
  static ModNumber invFact(T n) {
    assert(0<=n && n<=FACT_MAX);
    static ModNumber inverse(T n) {
      assert(1<=n && n<=FACT_MAX);
      static ModNumber[] memo;
      if (memo.length == 0) {
        memo = new ModNumber[FACT_MAX+1];
      }
      if (memo[n] != ModNumber.init) {
        return memo[n];
      } else {
        return memo[n] = n==1 ? ModNumber(1) : ModNumber(-mod/n)*inverse(mod%n);
      }
    }
    static ModNumber[] memo;
    if (memo.length == 0) {
      memo = new ModNumber[FACT_MAX+1];
      memo[0] = ModNumber(1);
      assert(memo[0] != ModNumber.init);
    }
    foreach_reverse(i; 0..n+1) {
      if (memo[i] != ModNumber.init) {
        foreach(j; i+1..n+1) {
          memo[j] = memo[j-1] * inverse(j);
        }
        return memo[n];
      }
    }
    assert(false);
  }

  // {}_n C_r: 組合せ
  static ModNumber comb(T n, T r) {
    import std.functional : memoize;
    if (r<0 || r>n) return ModNumber(0);
    if (r*2 > n) return comb(n, n-r);

    if (n<=FACT_MAX) {
      return fact(n) * invFact(r) * invFact(n-r); // 逆元テーブルを使用する
      // return fact(n) / fact(r) / fact(n-r); // 逆元テーブルを使用しない
    }

    ModNumber mul(T l, T r) {
      return l>r ? ModNumber(1) : l * memoize!mul(l+1, r);
    }
    return memoize!mul(n-r+1, n) / memoize!mul(1, r);
  }

  // {}_n H_r: 重複組合せ (Homogeneous Combination)
  static ModNumber hComb(T n, T r) {
    return comb(n+r-1, r);
  }

  string toString() {
    import std.conv;
    return this.value.to!string;
  }

  invariant {
    assert(this.value>=0);
    assert(this.value<mod);
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
