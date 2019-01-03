package fpinscala.purestate

import org.specs2.Specification

class RngSpec extends Specification {
  def is =
    s2"""
        RNG must return a pseudo-random number $exer1
        RNG.nonNegativeInt must generate a non negative random number $exer2
        RNG.double must return a value between 0 and 1 $exer3
        RNG.ints must return a list of random integers $exer4
        RNG.sequence should swap the types List[Rand[A]] to Rand[List[A]] $exer5
        RNG.randInts should return a list of 5 random integers $exer6
      """

  def exer1 = {
    val (n1, rng1) = SimpleRNG(123456789).nextInt
    n1 must_== 1820451251
    val (n2, rng2) = rng1.nextInt
    n2 must_== 1221384887
    val (n3, rng3) = rng2.nextInt
    n3 must_== 1220957452
  }

  def exer2 = {
    RNG.nonNegativeInt(SimpleRNG(123489))._1 >= 0 must_== true
  }

  def exer3 = {
    executeN(1000) {
      r => {
        val d = RNG.double(r)._1
        (d >= 0.0 && d < 1.0) must_== true
        r
      }
    }
  }

  def executeN(steps: Int)(f: RNG => RNG) = {
    var rng: RNG = SimpleRNG(123324)
    for (_ <- 0 to steps) {
      rng = f(rng.nextInt._2)
    }
    true must_== true
  }

  def exer4 = {
    val rng: RNG = SimpleRNG(123456)
    RNG.ints(5)(rng)._1.size must_== 5
  }

  def exer5 = {
    val l : List[RNG.Rand[Double]] = List(rng => RNG.double(rng), rng => RNG.double(rng), rng => RNG.double(rng))

    RNG.sequence(l)(SimpleRNG(123324))._1.size must_== 3
  }

  def exer6 = {
    val l = RNG.randInts(5)(SimpleRNG(123324))._1
    l.size must_== 5
    l.forall(n => l.count(_ == n) == 1)
  }
}