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

struct P {
    long t, x;
}
void main() {
    long W, H, Q;
    scanln(W, H, Q);
    P[] ps, qs;
    foreach(_; 0..Q) {
        long t, d, x;
        scanln(t, d, x);
        x--;
        if (d==0) {
            ps ~= P(t, x);
        } else {
            qs ~= P(t, x);
        }
    }
    long a = f(
        W,
        ps.sort!"a.t<b.t".chunkBy!"a.t==b.t".map!(
            ps => ps.array.sort!"a.x<b.x".array
        ).array
    );
    long b = f(
        H,
        qs.sort!"a.t<b.t".chunkBy!"a.t==b.t".map!(
            ps => ps.array.sort!"a.x<b.x".array
        ).array
    );
    if (a>=INF || b>=INF) {
        writeln(-1);
    } else {
        writeln(a+b);
    }
}

long f(long N, P[][] pss) {
    auto seg = SegTree!(long, (a, b) => min(a, b), INF)(N.rep!(()=>0L));
    long[] xs;
    foreach(ps; pss) {
        xs = [];
        foreach(p; ps) {
            xs ~= p.x;
            seg.update(p.x, INF);
        }
        foreach(x; xs) {
            long l, r;
            l=x, r=N-1;
            while(r-l>1) {
                long c = (l+r)/2;
                long v = seg.query(x, c+1);
                if (v < INF) {
                    r = c;
                } else {
                    l = c;
                }
            }
            seg.update(x, min(seg.get(x), seg.get(r)+(r-x)));

            l=0, r=x;
            while(r-l>1) {
                long c = (l+r)/2;
                long v = seg.query(c, x+1);
                if (v < INF) {
                    l = c;
                } else {
                    r = c;
                }
            }
            seg.update(x, min(seg.get(x), seg.get(l)+(x-l)));
        }
    }
    return seg.query(0, N);
}

// RMQ (Range Minimum Query)
// alias RMQ(T) = SegTree!(T, (a, b) => a<b ? a:b, T.max);

// SegTree (Segment Tree)
struct SegTree(T, alias fun, T initValue)
    if (is(typeof(fun(T.init, T.init)) : T)) {

private:
    Node[] _data;
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
        _data.length = _size*2-1;
        _data[] = Node(size_t.max, initValue);
        _l = 0;
        _r = size;
    }

    // i番目の要素をxに変更
    // O(logN)
    void update(size_t i, T x) {
        size_t index = i;
        i += _size-1;
        _data[i] = Node(index, x);
        while(i > 0) {
            i = (i-1)/2;
            Node nl = _data[i*2+1];
            Node nr = _data[i*2+2];
            _data[i] = select(nl, nr);
        }
    }

    // 配列で指定
    // O(N)
    void update(T[] ary) {
        foreach(i, e; ary) {
            _data[i+_size-1] = Node(i, e);
        }
        foreach(i; (_size-1).iota.retro) {
            Node nl = _data[i*2+1];
            Node nr = _data[i*2+2];
            _data[i] = select(nl, nr);
        }
    }

    // 区間[a, b)でのクエリ (値の取得)
    // O(logN)
    T query(size_t a, size_t b) {
        return queryRec(a, b, 0, 0, _size).value;
    }

    // 区間[a, b)でのクエリ (indexの取得)
    // O(logN)
    size_t queryIndex(size_t a, size_t b) out(result) {
        // fun == (a, b) => a+b のようなときはindexを聞くとassertion
        assert(result != size_t.max);
    } body {
        return queryRec(a, b, 0, 0, _size).index;
    }

    private Node queryRec(size_t a, size_t b, size_t k, size_t l, size_t r) {
        if (b<=l || r<=a) return Node(size_t.max, initValue);
        if (a<=l && r<=b) return _data[k];
        Node nl = queryRec(a, b, k*2+1, l, (l+r)/2);
        Node nr = queryRec(a, b, k*2+2, (l+r)/2, r);
        return select(nl, nr);
    }

    private Node select(Node nl, Node nr) {
        T v = fun(nl.value, nr.value);
        if (nl.value == v) {
            return nl;
        } else if (nr.value == v) {
            return nr;
        } else {
            return Node(size_t.max, v);
        }
    }

    // O(1)
    T get(size_t i) {
        return _data[_size-1 + i].value;
    }

    // O(N)
    T[] array() {
        return _data[_l+_size-1.._r+_size-1].map!"a.value".array;
    }

private:
    struct Node {
        size_t index;
        T value;
    }
}


// ----------------------------------------------

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
    enum string str = [staticMap!(getFormat, Args)].join(" ") ~ "\n";
    // readf!str(args);
    mixin("str.readf(" ~ Args.length.iota.map!(i => "&args[%d]".format(i)).join(", ") ~ ");");
}

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

T ceil(T)(T x, T y) if (__traits(isIntegral, T)) {
    // `(x+y-1)/y` will only work for positive numbers ...
    T t = x / y;
    if (t * y < x) t++;
    return t;
}

T floor(T)(T x, T y) if (__traits(isIntegral, T)) {
    T t = x / y;
    if (t * y > x) t--;
    return t;
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
    auto minElement(alias map, Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
    {
        alias mapFun = unaryFun!map;
        auto element = r.front;
        auto minimum = mapFun(element);
        r.popFront;
        foreach(a; r) {
            auto b = mapFun(a);
            if (b < minimum) {
                element = a;
                minimum = b;
            }
        }
        return element;
    }
    auto maxElement(alias map, Range)(Range r)
    if (isInputRange!Range && !isInfinite!Range)
    {
        alias mapFun = unaryFun!map;
        auto element = r.front;
        auto maximum = mapFun(element);
        r.popFront;
        foreach(a; r) {
            auto b = mapFun(a);
            if (b > maximum) {
                element = a;
                maximum = b;
            }
        }
        return element;
    }
}
