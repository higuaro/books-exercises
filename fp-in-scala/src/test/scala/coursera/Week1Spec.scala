package coursera

import org.specs2.Specification

class Week1Spec extends Specification { def is = s2"""
  Specification for week1 exercises from the Scala Coursera course:
    The pascal triangle for (0, 0) should be 1   ${exer1(0, 0, 1)}
    The pascal triangle for (1, 0) should be 1   ${exer1(1, 0, 1)}
    The pascal triangle for (1, 1) should be 1   ${exer1(1, 1, 1)}
    The pascal triangle for (2, 0) should be 1   ${exer1(2, 0, 1)}
    The pascal triangle for (2, 1) should be 2   ${exer1(2, 1, 2)}
    The pascal triangle for (2, 2) should be 1   ${exer1(2, 2, 1)}
    The pascal triangle for (3, 0) should be 1   ${exer1(3, 0, 1)}
    The pascal triangle for (3, 1) should be 3   ${exer1(3, 1, 3)}
    The pascal triangle for (3, 2) should be 3   ${exer1(3, 2, 3)}
    The pascal triangle for (3, 3) should be 1   ${exer1(3, 3, 1)}
    The pascal triangle for (4, 0) should be 1   ${exer1(4, 0, 1)}
    The pascal triangle for (4, 1) should be 4   ${exer1(4, 1, 4)}
    The pascal triangle for (4, 2) should be 6   ${exer1(4, 2, 6)}
    The pascal triangle for (4, 3) should be 4   ${exer1(4, 3, 4)}
    The pascal triangle for (4, 4) should be 1   ${exer1(4, 4, 1)}

  Specifications for exercise 2, checking if the parenthesis of a string are balanced:
    "(if (zero? x) max (/ 1 x))"  is balanced                                      ${exer2("(if (zero? x) max (/ 1 x))", balanced = true)}
    "I told him (that it’s not (yet) done). (But he wasn’t listening)" is balanced ${exer2("I told him (that it’s not (yet) done). (But he wasn’t listening)", balanced = true)}
    ":((---)" is not balanced                                                      ${exer2(":((---)", balanced = false)}
    "())(" is not balanced                                                         ${exer2("())(", balanced = false)}

  Specifications for exercise 3, count change problem:
    There are 4 ways to represent 6 with coins 1 and 2   ${exer3(4)}
  """

  def exer1(row: Int, col: Int, value: Int) =
    Week1.pascal(row, col) must_== value

  def exer2(string: String, balanced: Boolean) =
    Week1.balance(string.toList) must_== balanced

  def exer3(expected: Int) =
    Week1.countChange(6, List(1, 2)) must_== expected
}
