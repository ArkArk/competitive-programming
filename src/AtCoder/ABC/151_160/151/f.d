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
import std.regex;
import core.bitop : popcnt;
alias Generator = std.concurrency.Generator;

enum long INF = long.max/5;

void main() {
  with(Geometry2d!double) {
    long N;
    scanln(N);

    Vec[] vs = new Vec[N];
    foreach(i; 0..N) {
      scanln(vs[i].x, vs[i].y);
    }

    double left = 0.0;
    double right = 1e8;
    foreach(_1; 0..100) {
      double radius = (left + right)/2;
      bool ok = false;
      foreach(i, u; vs) foreach(v; vs[i+1..$]) {
        Vec[] ts = collide(Circle(u, radius), Circle(v, radius));
        foreach(t; ts) {
          if (vs.all!(w => w.dist(t) < radius + EPS)) {
            ok = true;
          }
        }
      }
      if (ok) {
        right = radius;
      } else {
        left = radius;
      }
    }

    writefln("%0.8f", left);
  }
}

import std.traits : isIntegral, isFloatingPoint;

template Geometry2d(T: double, double _EPS = 1e-7)
if (isIntegral!T || isFloatingPoint!T)
{
  import std.math;
  import std.range;
  import std.conv;

  enum EPS = _EPS;

  struct Vec {
    T x = 0;
    T y = 0;

    this(T x, T y) {
      this.x = x;
      this.y = y;
    }

    this(Vec v) {
      this.x = v.x;
      this.y = v.y;
    }

    Vec opBinary(string op)(Vec that) {
      return Vec(
        mixin("this.x" ~ op ~ "that.x"),
        mixin("this.y" ~ op ~ "that.y"),
      );
    }

    Vec opBinary(string op)(T that) {
      return Vec(
        mixin("this.x" ~ op ~ "that"),
        mixin("this.y" ~ op ~ "that"),
      );
    }

    bool inCircle(Circle circle) {
      T d2 = distSq(circle.center, this.pos);
      T r2 = circle.radius * circle.radius;
      return d2 <= r2 || d2.eq(r2);
    }

    Vec pos() {
      return this;
    }
  }

  alias Point = Vec;

  struct Line {
    Vec pos = Vec(0, 0);
    Vec dir = Vec(1, 0);
  }

  struct Segment {
    Vec beginPos = Vec(0, 0);
    Vec endPos = Vec(0, 0);
  }

  struct Circle {
    Vec center = Vec(0, 0);
    T radius = 1;
  }

  struct Polygon {
    Vec[] ps;
  }

  bool eq(U: double)(U a, U b) pure
  if (isIntegral!U || isFloatingPoint!U)
  {
    static if (isFloatingPoint!U) {
      return abs(a - b) < EPS;
    } else {
      return a == b;
    }
  }

  bool eq(Vec a, Vec b) pure {
    return eq(a.x, b.x) && eq(a.y, b.y);
  }

  T dot(Vec a, Vec b) pure {
    return a.x*b.x + a.y*b.y;
  }

  T cross(Vec a, Vec b) pure {
    return a.x*b.y - a.y*b.x;
  }

  T lengthSq(Vec a) pure {
    return a.x*a.x + a.y*a.y;
  }

  double length(Vec a) pure {
    return a.lengthSq.to!double.sqrt;
  }

  T distSq(Vec a, Vec b) pure {
    return lengthSq(a - b);
  }

  double dist(Vec a, Vec b) pure {
    return length(a - b);
  }

  // 偏角
  // @return: in [0, 2*PI)
  double arg(Vec a) pure {
    double res = atan2(a.y.to!double, a.x.to!double);
    return (res + 2*PI) % (2*PI);
  }

  static if (isFloatingPoint!T) {
    // @param: theta [rad]
    Vec rotate(Vec a, T theta) pure {
      T c = cos(theta);
      T s = sin(theta);
      return Vec(
        c*a.x - s*a.y,
        s*a.x + c*a.y,
      );
    }
  }

  // ベクトル a, b の成す角
  // @param: [rad] in [0, PI)
  double getAngle(Vec a, Vec b) pure {
    return acos(dot(a, b) / a.length / b.length);
  }

  int ccw(Vec a, Vec b, Vec c) {
    T crs = cross(b - a, c - a);
    if (crs > +EPS) return +1; // 半時計回り
    if (crs < -EPS) return -1; // 時計回り
    return 0;
  }

  // functions for shapes

  double dist(Point a, Line b) pure {
    return cross(a.pos - b.pos, b.dir).abs / b.dir.length;
  }

  double dist(Line a, Point b) pure {
    return dist(b, a);
  }

  Vec[] collide(Point a, Point b) pure {
    if (a.pos.eq(b.pos)) {
      return [a.pos];
    } else {
      return [];
    }
  }

  Vec[] collide(Point a, Line b) pure {
    if (cross(a.pos - b.pos, b.dir).eq(0)) {
      return [a.pos];
    } else {
      return [];
    }
  }

  Vec[] collide(Line a, Point b) pure {
    return collide(b, a);
  }

  Vec[] collide(Point a, Segment b) pure {
    Vec v1 = b.endPos - b.beginPos;
    Vec v2 = a.pos - b.beginPos;
    double d1 = v1.length;
    double d2 = v2.length;
    if (dot(v1, v2).eq(d1 * d2) && d2 < d1 + EPS) {
      return [a.pos];
    } else {
      return [];
    }
  }

  Vec[] collide(Segment a, Point b) pure {
    return collide(b, a);
  }

  static if (isFloatingPoint!T) {
    Vec[] collide(Line a, Line b) pure {
      double crs0 = cross(a.dir, b.dir);

      if (crs0.eq(0)) {

        return collide(Point(a.pos), b);

      } else {

        Vec v = b.pos - a.pos;
        double crs2 = cross(v, b.dir);
        double t1 = crs2 / crs0;

        return [a.pos + a.dir*t1];

      }
    }
  }

  static if (isFloatingPoint!T) {
    Vec[] collide(Segment a, Segment b) pure {

      Vec aDir = a.endPos - a.beginPos;
      Vec bDir = b.endPos - b.beginPos;

      double crs0 = cross(aDir, bDir);

      if (crs0.eq(0)) {

        Vec[] result;
        if (result.empty) result = collide(Point(a.beginPos), b);
        if (result.empty) result = collide(Point(a.endPos), b);
        if (result.empty) result = collide(a, Point(b.beginPos));
        if (result.empty) result = collide(a, Point(b.endPos));
        return result;

      } else {

        Vec v = b.beginPos - a.beginPos;
        double crs1 = cross(v, aDir);
        double crs2 = cross(v, bDir);

        double t1 = crs2 / crs0;
        double t2 = crs1 / crs0;

        if (t1 + EPS < 0 || t1 - EPS > 1 || t2 + EPS < 0 || t2 - EPS > 1) {
          return [];
        } else {
          return [a.beginPos + aDir*t1];
        }

      }
    }
  }

  static if (isFloatingPoint!T) {
    Vec[] collide(Circle a, Circle b) pure
    in {
      assert(!a.center.eq(b.center));
    } body {
      double d = dist(a.center, b.center);

      if (abs(a.radius - b.radius) > d + EPS) return [];
      if (a.radius + b.radius < d - EPS) return [];

      double alpha = acos(
        (a.radius*a.radius + d*d - b.radius*b.radius) / (2*a.radius*d)
      );
      double theta = (b.center - a.center).arg;
      Vec v1 = a.center + Vec(cos(theta + alpha)*a.radius, sin(theta + alpha)*a.radius);
      Vec v2 = a.center + Vec(cos(theta - alpha)*a.radius, sin(theta - alpha)*a.radius);

      return [v1, v2];
    }
  }
}

pure unittest {
  import std.math : sqrt, PI;

  with(Geometry2d!long) {
    auto v = Vec(2, 5);
    assert(v.x == 2);
    assert(v.y == 5);

    auto u = Vec(3, 1);
    assert(v + u == Vec(5, 6));
    assert(v - u == Vec(-1, 4));
    assert(v * u == Vec(6, 5));
    assert(v / u == Vec(0, 5));
    assert(v ^^ u == Vec(8, 5));

    assert(v + 1 == Vec(3, 6));
    assert(v - 3 == Vec(-1, 2));
    assert(v * 2 == Vec(4, 10));
    assert(v / 2 == Vec(1, 2));
    assert(v ^^ 2 == Vec(4, 25));

    assert(v.dot(u) == 6 + 5);
    assert(v.cross(u) == 2 - 15);
    assert(v.lengthSq == 4 + 25);
    assert(v.length.eq(sqrt(29.0)));
    assert(v.distSq(u) == 1 + 16);
    assert(v.dist(u).eq(sqrt(17.0)));

    assert(Vec(10, 10).arg.eq(PI/4));
  }
}

pure unittest {
  import std.math : sqrt, PI;

  with(Geometry2d!double) {
    Vec v;
    assert(v.x.eq(0));
    assert(v.y.eq(0));

    v = Vec(2, 5);
    assert(v.x.eq(2));
    assert(v.y.eq(5));
    assert(v.eq(Vec(2, 5)));

    auto u = Vec(3, 1);
    assert((v + u).eq(Vec(5, 6)));
    assert((v - u).eq(Vec(-1, 4)));
    assert((v * u).eq(Vec(6, 5)));
    assert((v / u).eq(Vec(2.0/3.0, 5)));
    assert((v ^^ u).eq(Vec(8, 5)));

    assert((v + 1).eq(Vec(3, 6)));
    assert((v - 3).eq(Vec(-1, 2)));
    assert((v * 2).eq(Vec(4, 10)));
    assert((v / 2).eq(Vec(1, 2.5)));
    assert((v ^^ 2).eq(Vec(4, 25)));

    assert(v.dot(u).eq(6 + 5));
    assert(v.cross(u).eq(2 - 15));
    assert(v.lengthSq.eq(4 + 25));
    assert(v.length.eq(sqrt(29.0)));
    assert(v.distSq(u).eq(1 + 16));
    assert(v.dist(u).eq(sqrt(17.0)));

    assert(Vec(10, 10).arg.eq(PI/4));
    assert(Vec(100, 100*sqrt(3.0)).arg.eq(PI/3));
    assert(Vec(100, -100*sqrt(3.0)).arg.eq(5*PI/3));

    assert(getAngle(Vec(1, 0), Vec(100, 100*sqrt(3.0))).eq(PI/3));
    assert(getAngle(
      Vec(100, 100*sqrt(3.0)),
      Vec(100, -100*sqrt(3.0))
    ).eq(2*PI/3));
  }
}

pure unittest {
  with(Geometry2d!double) {
    // distance between Point and Line

    assert(dist(
      Point(Vec(1, 1)),
      Line(Vec(-3, 1), Vec(0, 1))
    ).eq(4));

    assert(dist(
      Point(Vec(1, 1)),
      Line(Vec(1, 1), Vec(0, 1))
    ).eq(0));
  }
}

unittest {
  import std.math : sqrt;
  import std.algorithm : any, all;

  with(Geometry2d!double) {
    Vec[] result;

    // Point vs. Point

    result = collide(
      Point(Vec(10, 5)),
      Point(Vec(10, 5))
    );
    assert(result.length == 1 && result[0].eq(Vec(10, 5)));

    result = collide(
      Point(Vec(10, 5)),
      Point(Vec(10, 4))
    );
    assert(result.length == 0);

    // Point vs. Line

    result = collide(
      Point(Vec(1, 3)),
      Line(Vec(-1, 3), Vec(1, 0))
    );
    assert(result.length == 1 && result[0].eq(Vec(1, 3)));

    result = collide(
      Point(Vec(1, 1)),
      Line(Vec(-1, 3), Vec(1, 0))
    );
    assert(result.length == 0);

    // Point vs. Segment

    result = collide(
      Point(Vec(0, 1)),
      Segment(Vec(-1, 1), Vec(1, 1))
    );
    assert(result.length == 1 && result[0].eq(Vec(0, 1)));

    result = collide(
      Point(Vec(-2, 1)),
      Segment(Vec(-1, 1), Vec(1, 1))
    );
    assert(result.length == 0);

    result = collide(
      Point(Vec(2, 1)),
      Segment(Vec(-1, 1), Vec(1, 1))
    );
    assert(result.length == 0);

    // Line vs. Line

    result = collide(
      Line(Vec(0, 1), Vec(1, 0)),
      Line(Vec(2, 0), Vec(0, 1))
    );
    assert(result.length == 1 && result[0].eq(Vec(2, 1)));

    result = collide(
      Line(Vec(0, 1), Vec(1, 0)),
      Line(Vec(2, 0), Vec(1, 0))
    );
    assert(result.length == 0);

    result = collide(
      Line(Vec(0, 1), Vec(1, 0)),
      Line(Vec(2, 1), Vec(1, 0))
    );
    assert(result.length == 1);

    // Segment vs. Segment

    result = collide(
      Segment(Vec(0, 1), Vec(3, 1)),
      Segment(Vec(2, 0), Vec(2, 5))
    );
    assert(result.length == 1 && result[0].eq(Vec(2, 1)));

    result = collide(
      Segment(Vec(0, 1), Vec(1, 1)),
      Segment(Vec(2, 0), Vec(2, 5))
    );
    assert(result.length == 0);

    // Point vs. Circle

    assert(
      Point(Vec(1, 3)).inCircle(Circle(Vec(2, 2), 3))
    );
    assert(
      Point(Vec(1, 3)).inCircle(Circle(Vec(2, 2), sqrt(2.0)))
    );
    assert(
      !Point(Vec(1, 3)).inCircle(Circle(Vec(2, 2), 1))
    );

    // Ciecle vs. Circle

    result = collide(
      Circle(Vec(-1, 0), sqrt(2.0)),
      Circle(Vec(+1, 0), sqrt(2.0))
    );
    assert(
      result.length == 2 &&
      result.any!(v => v.eq(Vec(0, 1))) &&
      result.any!(v => v.eq(Vec(0, -1)))
    );

    result = collide(
      Circle(Vec(-1, 2), 3),
      Circle(Vec(2, 6), 2)
    );
    assert(
      result.length == 2 &&
      result.all!(
        v => v.eq(
          (Vec(-1, 2)*2 + Vec(2, 6)*3) / 5
        )
      )
    );

    result = collide(
      Circle(Vec(-1, 2), 3),
      Circle(Vec(2, 6), 1)
    );
    assert(result.length == 0);
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
  if (y > 0 && t * y < x) t++;
  if (y < 0 && t * y > x) t++;
  return t;
}

T floor(T)(T x, T y) if (isIntegral!T || is(T == BigInt)) {
  T t = x / y;
  if (y > 0 && t * y > x) t--;
  if (y < 0 && t * y < x) t--;
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
  enum fmt = n.rep!(()=>"%s").join(sep);

  string line = readln.chomp;
  static if (__VERSION__ >= 2074) {
    line.formattedRead!fmt(args);
  } else {
    enum argsTemp = n.iota.map!(
      i => "&args[%d]".format(i)
    ).join(", ");
    mixin(
      "line.formattedRead(fmt, " ~ argsTemp ~ ");"
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
