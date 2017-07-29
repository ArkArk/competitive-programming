import std.stdio;
import std.string;
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
import std.ascii;
import std.concurrency;

const int INF = int.max/3;
class Vertex{
    Edge[] es;
    Edge rev;
    int a = INF;
    bool visited = false;
    bool hasLoop = false;
}
struct Edge{
    Vertex s, g;
}
void main() {
    int N = readln.chomp.to!int;
    Vertex[] vs = N.rep!(() => new Vertex);
    readln.split.to!(int[]).map!"a-1".enumerate.each!(
        (a) {
            vs[a.value].es ~= Edge(vs[a.value], vs[a.index]);
            vs[a.index].rev = Edge(vs[a.value], vs[a.index]);
        }
    );

    Vertex po;

    int f(Vertex v, Vertex root) {
        if (v.visited) return v.a;

        v.visited = true;
        auto tree = redBlackTree!("a<b", false, int);
        foreach(e; v.es) {
            if (e.g is root) {
                tree.insert(-1);
            } else {
                tree.insert(f(e.g, root));
            }
        }
        if (tree.empty) {
            return v.a = 0;
        } else if (tree.front < 0) {
            po = v;
            v.hasLoop = true;
            return v.a = -1;
        } else {
            foreach(n; 0..v.es.length+1) {
                if (n == tree.front) {
                    tree.removeFront;
                } else {
                    return v.a = n.to!int;
                }
            }
            assert(false);
        }
    }
    vs.each!(v => f(v, v));

    assert(po !is null && po.hasLoop);

    int g(Vertex v, int k=0) {
        auto tree = redBlackTree!("a<b", false, int);
        foreach(e; v.es) {
            if (e.g.a>=0) tree.insert(e.g.a);
        }
        foreach(n; 0..v.es.length+1) {
            if (!tree.empty && n == tree.front) {
                tree.removeFront;
            } else {
                if (k--==0) return n.to!int;
            }
        }
        assert(false);
    }

    2.iota.map!(i => g(po, i)).array.any!(
        (n) {
            po.a = n;
            bool h(Vertex v) {
                assert(v.hasLoop);
                if (v is po) {
                    return g(v) == po.a;
                } else {
                    v.a = g(v);
                    return h(v.rev.s);
                }
            }
            return h(po.rev.s);
        }
    ).pipe!(flg => flg?"POSSIBLE":"IMPOSSIBLE").writeln;
}

// ----------------------------------------------

void times(alias fun)(int n) {
    // n.iota.each!(i => fun());
    foreach(i; 0..n) fun();
}
auto rep(alias fun, T = typeof(fun()))(int n) {
    // return n.iota.map!(i => fun()).array;
    T[] res = new T[n];
    foreach(ref e; res) e = fun();
    return res;
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