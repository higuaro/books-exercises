package fpinscala.errorhandling

import org.specs2.Specification

class OptionSpec extends Specification { def is = s2"""
  Option[T] related exercises for Chapter 4:
    Use map function to increment the value of an Option[Int]         $exer1
    sequence must return None if there is a None in the list          $exerSeq
    sequence must return Some(List(1, 2)) for List(Some(1), Some(2))  $exerSeq2
    sequence must return Some(List()) for List()                      $exerSeq3
    Traverse must square all number in List(1, 2, 3, 4)               $exerTraverse
    Traverse must return None for List(1, 2, oo, 4)                   $exerTraverseWithNone
    Traverse must return Some(List()) for List()                      $exerTraverseWithNone2
  """

  def exer1 =
    Some(4).map(_ + 1) must_== Some(5)

  def exerSeq = {
    val options = List(Some(1), None(), Some(2), Some(3))
    Option.sequence(options) must_== None()
    Option.sequence_1(options) must_== None()
    Option.sequence_2(options) must_== None()
    Option.sequence_t(options) must_== None()
  }

  def exerSeq2 = {
    val options = List(Some(1), Some(2))
    val result = Some(List(1, 2))
    Option.sequence(options) must_== result
    Option.sequence_1(options) must_== result
    Option.sequence_2(options) must_== result
    Option.sequence_t(options) must_== result
  }

  def exerSeq3 = {
    val options: List[Option[Int]] = List()
    val result: Option[List[Int]] = Some(List())
    Option.sequence(options) must_== result
    Option.sequence_1(options) must_== result
    Option.sequence_2(options) must_== result
    Option.sequence_t(options) must_== result
  }

  def exerTraverse =
    Option.traverse(List(1, 2, 3, 4))(n => Some(n * n)) must_== Some(List(1, 4, 9, 16))

  def exerTraverseWithNone =
    Option.traverse(List(1, 2, Integer.MAX_VALUE, 4))(n => if (n != Integer.MAX_VALUE) Some(n * n) else None()) must_== None()

  def exerTraverseWithNone2 =
    Option.traverse(List() : List[Int])(n => Some(n + 1)) must_== Some(List())
}
