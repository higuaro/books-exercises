package fpinscala.errorhandling

import org.specs2.Specification

class MiscSpec extends Specification { def is = s2"""
  Answer to miscellanious exercises for Chapter 4:
    Write a function to calculate the variance of a sequence using flatMap.
    Using Seq(1, 3, 4, 1, 23), it should be 70.24000000000002   $exer1
    Write a map2 function, which takes a function f(A, B) => C as parameter  $exer2
  """

  def exer1 =
    Misc.variance(List(1, 3, 4, 1, 23)) must_== Some(70.24000000000002)

  def exer2 = {
    def calcSalary(name: String, job: String) = job match {
      case "boss" => 10000.0f
      case _ => name.size.toFloat * 100.0f
    }
    val optA = Some("Bob")
    val optB = Some("boss")

    Option.map2(optA, optB)(calcSalary) must_== Some(10000.0f)
    Option.map2(optA, None())(calcSalary) must_== None()
    Option.map2(None(), optB)(calcSalary) must_== None()
    Option.map2(None(), None())(calcSalary) must_== None()
  }
}
