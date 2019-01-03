package fpinscala.datastructures


sealed trait Tree[+A]
case class Leaf[A](value: A) extends Tree[A]
case class Branch[A](left: Tree[A], right: Tree[A]) extends Tree[A]

object Tree {
  def size[A](t: Tree[A]): Int = t match {
    case Branch(l, r) => size(l) + size(r)
    case Leaf(_) => 1
    case _ => 0
  }

  def maximum(t: Tree[Int]): Int = t match {
    case Branch(l, r) => maximum(l) max maximum(r)
    case Leaf(v) => v
  }

  def depth[A](t: Tree[A]): Int = {
    def loop(ts: Tree[A], d: Int): Int = ts match {
      case Branch(l, r) => loop(l, d + 1) max loop(r, d + 1)
      case Leaf(v) => d
    }
    loop(t, 0)
  }

  def map[A](t: Tree[A])(f: A => A): Tree[A] = t match {
    case Branch(l, r) => Branch(map(l)(f), map(r)(f))
    case Leaf(v) => Leaf(f(v))
  }
}
