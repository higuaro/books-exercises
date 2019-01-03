package fpinscala.datastructures

import org.specs2.Specification

class TreeSpec extends Specification { def is = s2"""
  Given the following tree:
             *
          /     \
        *         *
       / \       / \
      1   5     *   4
               / \
              3   6
    Its size is 5                        $exer1
    Its maximum node value is 6          $exer2
    Its depth is 4                       $exer3
    It should duplicate the node values  $exer4
  """

  private val tree = Branch(Branch(Leaf(1), Leaf(5)), Branch(Branch(Leaf(3), Leaf(6)), Leaf(4)))

  def exer1 =
    Tree.size(tree) must_== 5

  def exer2 =
    Tree.maximum(tree) must_== 6

  def exer3 =
    Tree.depth(tree) must_== 3

  def exer4 =
    Tree.map(tree){ _ * 2 } must_== Branch(Branch(Leaf(2), Leaf(10)), Branch(Branch(Leaf(6), Leaf(12)), Leaf(8)))

}
