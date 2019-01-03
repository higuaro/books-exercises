package fpinscala.datastructures

import org.specs2.Specification

class ListSpec extends Specification { def is = s2"""
  Specifications for the List data structure:
    Use the fold2 operation to count the elements in the List(1, 2, 3, 4), must be 4    $exer1
    Use the length operation to count the elements in the List(1, 2, 3, 4), must be 4   $exer2
    Should reverse the List(1, 2, 3, 4)   $exer3
    Should flatten the List(List(1, 2, 3), List(4, 5, 6), List(7, 8, 9))   $exer4
    Should increse by one the value of the elements of the List(1, 2, 3, 4)  $exer5
    Should square all elements of the List(1, 2, 3, 4)   $exer6
    Should filter the even numbers from List(1, 2, 3, 4, 5)  $exer7
    Should filter the even numbers from List(1, 2, 3, 4, 5)  $exer8
    Should duplicate the elements of the List(1, 2, 3)  $exer9
    Should sum the elements of the List(1, 2, 3, 4) and List(1, 2, 3, 4, 5)  $exer10
    Should subtract the elements of the List(1, 2, 3, 4) and List(1, 2, 3, 4, 5)  $exer11
    The List(1, 2, 3, 4) contains the subsequence (1, 2)  $exer12
    The List(1, 2, 3, 4) contains the subsequence (3, 4)  $exer13
    The List(1, 2, 3, 4) contains the subsequence (4)  $exer14
    The List(1, 2, 3, 4) does not contain the subsequence (1, 3)  $exer15
  """
  private val list = List(1, 2, 3, 4)

  def exer1 =
    List.foldRight2(list, 0)((a, n) => n + 1) must_== 4

  def exer2 =
    List.length(list) must_== 4

  def exer3 =
    List.reverse(list) must_== List(4, 3, 2, 1)

  def exer4 =
    List.flat(List(List(1, 2, 3), List(4, 5, 6), List(7, 8, 9))) must_== List(1, 2, 3, 4, 5, 6, 7, 8, 9)

  def exer5 =
    List.increaseElems(list) must_== List(2, 3, 4, 5)

  def exer6 =
    List.map(list)(i => i * i) must_== List(1, 4, 9, 16)

  def exer7 =
    List.filter(List(1, 2, 3, 4, 5))(i => i % 2 == 1) must_== List(1, 3, 5)

  def exer8 =
    List.filter2(List(1, 2, 3, 4, 5))(i => i % 2 == 1) must_== List(1, 3, 5)

  def exer9 =
    List.flatMap(List(1, 2, 3))(i => List(i, i)) must_== List(1, 1, 2, 2, 3, 3)

  def exer10 =
    List.sumLists(list, List(1, 2, 3, 4, 5)) must_== List(2, 4, 6, 8)

  def exer11 =
    List.zipWith(list, List(1, 2, 3, 4, 5))((a1, a2) => a1 - a2) must_== List(0, 0, 0, 0)

  def exer12 =
    List.hasSubsequence(list, List(1, 2)) must_== true

  def exer13 =
    List.hasSubsequence(list, List(3, 4)) must_== true

  def exer14 =
    List.hasSubsequence(list, List(4)) must_== true

  def exer15 =
    List.hasSubsequence(list, List(1, 3)) must_== false
}
