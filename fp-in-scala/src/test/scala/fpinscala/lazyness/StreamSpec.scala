package fpinscala.lazyness

import org.specs2.Specification


class StreamSpec extends Specification { def is = s2"""
  Stream[T] related exercises for Chapter 5:
    Must create a List[A] from a Stream[A]    $exer1

    take should return:
      a new Stream with the first 3 elements from Stream(1, 2, 3, 4, 5) $exer2
      an empty Stream after taking 2 from Stream() $exer3

    drop should:
      return a new Stream with the last 3 elements from Stream(1, 2, 3, 4, 5) $exer4
      return the whole Stream after dropping 0 elements from Stream(1, 2, 3) $exer5

    takeWhile should:
      return Stream(1) using predicate `if e == 1` on Stream(1, 2, 3) $exer6
      return Stream() using predicate `if e == 2` on Stream(1, 2, 3) $exer7

    forAll should:
      return true using predicate `e > 0` on Stream(1, 2, 3) $exer8
      return false using predicate `e > 0` on Stream(1, 2, 0, 4, 5) and the predicate must be executed only 3 times $exer9

    takeWhile2 should:
      return Stream(1, 2, 3) when predicate is `e < 4` on Stream(1, 2, 3, 4, 5) $exer10
      return Stream() when predicate is `e < 0` on Stream(1, 2, 3) $exer11

    headOption should:
      return Some(1) for Stream(1, 2, 3)  $exer12
      return None() for Stream() $exer13

    map should:
      return Stream(1, 4, 9) `f(x) => x^2` for Stream(1, 2, 3)  $exer14

    filter should:
      return Stream() for predicate `x < 0` on Stream(1, 2, 3)  $exer15
      return Stream(1, 3) for predicate `x.isOdd` on Stream(1, 2, 3)  $exer16

    append should:
      return Stream(1, 2, 3, 4) given Stream(3, 4) to an existing Stream(1, 2)  $exer17

    flatMap should:
      return Stream(2, 3, 4) given Stream(1, 2, 3) and the f(x) => x + 1 $exer18

    exists should return true when:
      the predicate is (x > 2) on Stream(-1, 0, 1, 2, 3) $exer22

    exists should return false when:
      the predicate is (x > 2) on Stream(-1, 0, 1, 2) $exer23

    find should return Some(1) when:
      given Stream(1, 2, 3, 4) and predicate (x == 1 || x == 4) $exer24
      given Stream(1, 2, 3, 4) and predicate (x == 1) $exer25

    find should return None when:
      given Stream(1, 2, 3, 4) and predicate (x == 0) $exer26
      given Stream() and predicate (x == 0) $exer27

    given `ones`, recursively defined as val ones = Stream.cons(1, ones), the following expressions should not hang:
      ones.map(_ + 1).exist(_ % 2 == 0)  $exer19
      ones.takeWhile(_ == 1)  $exer20
      ones.forAll(_ != 1)  $exer21

    Stream.constant should:
      not hang when instantiated $exer28
      return Stream(1, 1, 1, 1) when take(4) is invoked on the created constant stream $exer29

    Stream.from should:
      not hang when instantiated $exer30
      return Stream(5, 6, 7, 8) when take(4) is invoked on the created stream $exer31

    Stream.fibs should:
      return the first 7 elements of the Fibonacci sequence $exer32

    onesU (ones implemented using unfold) expressions should:
      return the Stream(1, 1, 1, 1) after invoking take(4) $exer33

    constantU (constant implemented using unfold) expressions should:
      return the Stream(5, 5, 5, 5) after invoking take(4) $exer34

    fibsU (fibs implemented using unfold) expressions should:
      return the Stream(0, 1, !, 2, 3, 5, 8) after invoking take(7) $exer35

    mapU should:
      return Stream(1, 4, 9) `f(x) => x^2` for Stream(1, 2, 3)  $exer36

    takeWhileU should:
      return Stream(1, 2, 3) when predicate is `e < 4` on Stream(1, 2, 3, 4, 5) $exer37
      return Stream() when predicate is `e < 0` on Stream(1, 2, 3) $exer38

    takeU should:
      a new Stream with the first 3 elements from Stream(1, 2, 3, 4, 5) $exer39
      an empty Stream after taking 2 from Stream() $exer40

    zipWith should:
      return Stream(2, 4, 6) for Stream(1, 2, 3) and paramter Stream(1, 2, 3) $exer41
      return Stream(2, 4, 6) for Stream(1, 2, 3, 4) and paramter Stream(1, 2, 3) $exer42
      return Stream(2, 4, 6) for Stream(1, 2, 3) and paramter Stream(1, 2, 3, 4) $exer43

    zipAll should:
      return Stream(Some(1) -> Some('a'), None -> Some('b')) for Stream(1) and given parameter Stream('a', 'b') $exer44

    startsWidth should:
      return true for Stream(1, 2) when invoked on Stream(1, 2, 3) $exer45
      return false for Stream(2, 3) when invoked on Stream(1, 2, 3) $exer46

    tails should:
      return Stream(Stream(1, 2), Stream(1)) for Stream(1, 2) $exer47

    scanRight should:
      return Stream(6, 5, 3, 0) when invoked like `Stream(1, 2, 3).scanRight(0)(_ + _)`
  """

  val ones: Stream[Integer] = Stream.cons(1, ones)

  def exer1 =
    Stream(1, 2, 3, 4, 5).toList must_== List(1, 2, 3, 4, 5)

  def exer2 =
    Stream(1, 2, 3, 4, 5).take(3).toList must_== List(1, 2, 3)

  def exer3 =
    Stream.empty.take(2) must_== Stream.empty

  def exer4 =
    Stream(1, 2, 3, 4, 5).drop(2).toList must_== List(3, 4, 5)

  def exer5 =
    Stream(1, 2, 3).drop(0).toList must_== List(1, 2, 3)

  def exer6 =
    Stream(1, 2, 3).takeWhile(_ == 1).toList must_== List(1)

  def exer7 =
    Stream(1, 2, 3).takeWhile(_ == 2).toList must_== List()

  def exer8 =
    Stream(1, 2, 3).forAll(_ > 0) must_== true

  def exer9 = {
    val s: Stream[Int] = Stream(1, 2, 0, 4, 5)
    var count: Int = 0

    s.forAll(a => {
      count += 1
      a > 0
    }) must_== false

    count must_== 3
  }

  def exer10 =
    Stream(1, 2, 3, 4, 5).takeWhile2(_ < 4).toList must_== List(1, 2, 3)

  def exer11 =
    Stream(1, 2, 3).takeWhile2(_ < 0).toList must_== List()

  def exer12 =
    Stream(1, 2, 3).headOption() must_== Some(1)

  def exer13 =
    Stream().headOption() must_== None

  def exer14 =
    Stream(1, 2, 3).map(x => x * x).toList must_== List(1, 4, 9)

  def exer15 =
    Stream(1, 2, 3).filter(_ < 0).toList must_== List()

  def exer16 =
    Stream(1, 2, 3).filter(x => (x % 2) == 1).toList must_== List(1, 3)

  def exer17 =
    Stream(1, 2).append(Stream(3, 4)).toList must_== List(1, 2, 3, 4)

  def exer18 =
    Stream(1, 2, 3).flatMap(x => Stream(x + 1)).toList must_== List(2, 3, 4)

  def exer19 =
    ones.map(_ + 1).exists(_ % 2 == 0) must_== true

  def exer20 = {
    val stream = ones.takeWhile(_ == 1)
    stream must_!= Stream.empty
  }

  def exer21 = {
    val stream = ones.forAll(_ != 1)
    stream must_!= Stream.empty
  }

  def exer22 =
    Stream(-1, 0, 1, 2, 3).exists(_ > 2) must_== true

  def exer23 =
    Stream(-1, 0, 1, 2).exists(_ > 2) must_== false

  def exer24 =
    Stream(1, 2, 3, 4).find(x => x == 1 || x == 4) must_== Some(1)

  def exer25 =
    Stream(1, 2, 3, 4).find(_ == 1) must_== Some(1)

  def exer26 =
    Stream(1, 2, 3, 4).find(_ == 0) must_== None

  def exer27 =
    Stream().find(_ == 0) must_== None

  def exer28 = {
    val c = Stream.constant(1)
    c must_!= Stream.empty
  }

  def exer29 =
    Stream.constant(1).take(4).toList must_== List(1, 1, 1, 1)

  def exer30 = {
    val f = Stream.from(5)
    f must_!= Stream.empty
  }

  def exer31 =
    Stream.from(5).take(4).toList must_== List(5, 6, 7, 8)

  def exer32 =
    Stream.fibs.take(7).toList must_== List(0, 1, 1, 2, 3, 5, 8)

  def exer33 =
    Stream.onesU.take(4).toList must_== List(1, 1, 1, 1)

  def exer34 =
    Stream.constantU(5).take(4).toList must_== List(5, 5, 5, 5)

  def exer35 =
    Stream.fibsU.take(7).toList must_== List(0, 1, 1, 2, 3, 5, 8)

  def exer36 =
    Stream(1, 2, 3).mapU(x => x * x).toList must_== List(1, 4, 9)

  def exer37 =
    Stream(1, 2, 3).takeWhileU(_ == 1).toList must_== List(1)

  def exer38 =
    Stream(1, 2, 3).takeWhileU(_ == 2).toList must_== List()

  def exer39 =
    Stream(1, 2, 3, 4, 5).takeU(3).toList must_== List(1, 2, 3)

  def exer40 =
    Stream.empty.takeU(2) must_== Stream.empty

  def exer41 =
    Stream(1, 2, 3).zipWith(Stream(1, 2, 3))( _ + _ ).toList must_== List(2, 4, 6)

  def exer42 =
    Stream(1, 2, 3, 4).zipWith(Stream(1, 2, 3))( _ + _ ).toList must_== List(2, 4, 6)

  def exer43 =
    Stream(1, 2, 3).zipWith(Stream(1, 2, 3, 4))( _ + _ ).toList must_== List(2, 4, 6)

  def exer44 =
    Stream(1).zipAll(Stream('a', 'b')).toList must_== List(Some(1) -> Some('a'), None -> Some('b'))

  def exer45 =
    Stream(1, 2, 3) startsWith Stream(1, 2) must_== true

  def exer46 =
    Stream(1, 2, 3) startsWith Stream(2, 3) must_== false

  def exer47 =
    Stream(1, 2).tails.toList.map(s => s.toList) must_== List(List(1, 2), List(2))

  def exer48 =
    Stream(1, 2, 3).scanRight(0)(_ + _).toList == List(6, 5, 3, 0)
}