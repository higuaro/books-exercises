package fpinscala.purestate

trait RNG {
  def nextInt: (Int, RNG)
}

case class SimpleRNG(seed: Long) extends RNG {
  def nextInt: (Int, RNG) = {
    val newSeed = (seed * 0x5DEECE66DL + 0xBL) & -1L
    val nextRNG = SimpleRNG(newSeed)
    val n = (newSeed >>> 16).toInt
    (n, nextRNG)
  }
}

object RNG {
  type Rand[+A] = RNG => (A, RNG)

  // val int: RNG => (Int, RNG) = rng => rng.nextInt
  // val int: Rand[Int] = rng => rng.nextInt
  val int: Rand[Int] = _.nextInt

  def unit[A](a: A): Rand[A] =
    rng => (a, rng)

  def map[A, B](rand: Rand[A])(f: A => B): Rand[B] = {
    rng => {
      val (a, rng2) = rand(rng)
      (f(a), rng2)
    }
  }

  def map2[A, B, C](ra: Rand[A], rb: Rand[B])(f: (A, B) => C): Rand[C] = {
    rng => {
      val (a, rngA) = ra(rng)
      val (b, rngB) = rb(rngA)
      (f(a, b), rngB)
    }
  }

  def both[A, B](ra: Rand[A], rb: Rand[B]): Rand[(A, B)] =
    map2(ra, rb)((_, _))

  val randIntDouble: Rand[(Int, Double)] =
    both(int, double)

  val randDoubleInt: Rand[(Double, Int)] =
    both(double, int)

  def nonNegativeInt(rng: RNG): (Int, RNG) = {
    val (n, rng2) = rng.nextInt

    (n & 0x7FFFFFFF, rng2)
  }

  def nonNegativeEven(rand: Rand[Int]): Rand[Int] = {
    map(rand) {
      i => i - (i % 2)
    }
  }

  def randDouble(rand: Rand[Int]): Rand[Double] = {
    map(rand) {
      n => n / Int.MaxValue.toDouble + 1.0
    }
  }

  def double(rng: RNG): (Double, RNG) = {
      val (n, rng2) = RNG.nonNegativeInt(rng)
      (n / (Int.MaxValue.toDouble + 1.0), rng2)
  }

  def intDouble(rng: RNG): ((Int, Double), RNG) = {
      val (n, rng2) = rng.nextInt
      val (d, rng3) = double(rng2)
      ((n, d), rng3)
  }

  def doubleInt(rng: RNG): ((Double, Int), RNG) = {
      val (n, rng2) = rng.nextInt
      val (d, rng3) = double(rng2)
      ((d, n), rng3)
  }

  def double3(rng: RNG): ((Double, Double, Double), RNG) = {
      val (d1, rng2) = double(rng)
      val (d2, rng3) = double(rng2)
      val (d3, rng4) = double(rng3)
      ((d1, d2, d3), rng4)
  }

  def ints(count: Int)(rng: RNG): (List[Int], RNG) = {
    if (count == 0)
      (List.empty, rng)
    else {
        val (n, rng2) = rng.nextInt
        val (l, rngN) = ints(count - 1)(rng2)
        (l ++ List(n), rngN)
    }
  }

  // List[RNG => (A, RNG)]
  // RNG => (List[A], RNG)
  def sequence[A](fs: List[Rand[A]]): Rand[List[A]] = {
    def go(rng: RNG, accum : List[A], fs: List[Rand[A]]): (List[A], RNG) = {
      fs match {
        case r :: rs =>
          val (a, rngA) = r(rng)
          go(rngA, accum ++ List(a), rs)
        case Nil =>
          (accum, rng)
      }
    }
    rng => go(rng, List.empty, fs)
  }

  def randInts(count: Int): Rand[List[Int]] = {
    sequence(
      List.fill(count)(1).map(_ => (rng : RNG) =>  rng.nextInt)
    )
  }
}