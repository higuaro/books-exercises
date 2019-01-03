package fpinscala.errorhandling

import org.specs2.Specification

class EitherSpec extends Specification { def is = s2"""
  Either[E, A] related exercises for Chapter 4:
    map function should square 2 for Right(2) and nothing for Left(NumberFormatException)  $exer1
    flatMap function should square the string "2" for Right("2") and Left(NumberFormatException) for Right("x")  $exer2

  """

  def exer1 = {
    val either1 = Right(2)
    val either2: Either[Exception, Int] = Left(new NumberFormatException)
    either1.map(n => n * n) must_== Right(4)
    either2.map(n => n * n) must_== Left(new NumberFormatException)
  }

  def exer2 = {
    val either1 = Right("2")
    val either2 = Right("x")

    def squareString(s: String): Either[Exception, Int] = {
      try {
        val v = s.toInt
        Right(v * v)
      } catch {
        case e: Exception => Left(e)
      }
    }

    either1.flatMap(s => squareString(s)) must_== Right(4)
    either2.flatMap(s => squareString(s)) must_== Left(new NumberFormatException)
  }
}
