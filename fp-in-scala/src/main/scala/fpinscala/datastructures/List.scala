package fpinscala.datastructures

sealed trait List[+A]
case object Nil extends List[Nothing]
case class Cons[+A](head: A, tail: List[A]) extends List[A]

object List {
  def sum(ints: List[Int]): Int = ints match {
    case Nil => 0
    case Cons(x, xs) => x + sum(xs)
  }

  def product(ds: List[Double]): Double = ds match {
    case Nil => 1.0
    case Cons(0.0, _) => 0.0
    case Cons(x, xs) => x * product(xs)
  }

  def apply[A](as: A*): List[A] =
    if (as.isEmpty) Nil
    else Cons(as.head, apply(as.tail: _*))

  // Exercise 3.2
  def tail[A](l: List[A]): List[A] = l match {
    case Cons(x, xs) => xs
    case _ => Nil
  }

  // Exercise 3.3
  def setHead[A](a: A, l: List[A]): List[A] =
    Cons(a, l)

  // Exercise 3.4
  def drop[A](l: List[A], n: Int): List[A] =
    if (n == 0) l else drop(tail(l), n - 1)

  // Exercise 3.5
  def dropWhile[A](l: List[A])(f: A => Boolean): List[A] =
    if (f(head(l))) dropWhile(tail(l))(f) else l

  def head[A](l: List[A]): A = l match {
    case Cons(x, _) => x
    case _ => throw new NoSuchElementException
  }

  // Exercise 3.6
  def init[A](l: List[A]): List[A] = l match {
    case Cons(x, Nil) => Nil
    case Cons(x, _) => Cons(x, init(tail(l)))
    case Nil => Nil
  }

  def foldRight[A, B](as: List[A], z: B)(f: (A, B) => B): B =
    as match {
      case Nil => z
      case Cons(x, xs) => f(x, foldRight(xs, z)(f))
    }

  def sum2(ns: List[Int]) =
    foldRight(ns, 0)((x, y) => x + y)

  def product3(ns: List[Double]) =
    foldLeft(ns, 1.0)(_ * _)

  def sum3(ns: List[Int]) =
    foldLeft(ns, 0)((x, y) => x + y)

  def length[A](ns: List[A]) =
    foldLeft(ns, 0)((acum, _) => acum + 1)

  def reverse[A](l: List[A]) =
    foldLeft(l, List(): List[A])((accum, x) => Cons(x, accum))

  @annotation.tailrec
  def foldLeft[A, B](as: List[A], z: B)(f: (B, A) => B): B = as match {
    case Nil => z
    case Cons(x, xs) => foldLeft(xs, f(z, x))(f)
  }
  // 1, 2, 3, 4, 5
  // Cons(1, [2, 3, 4, 5] =>
  //

  def foldRight2[A, B](as: List[A], z: B)(f: (A, B) => B): B =
    foldLeft(reverse(as), z)((b, a) => f(a, b))

  def append[A](l: List[A], r: List[A]): List[A] =
    foldRight(l, r)(Cons(_, _))

  def flat[A](l: List[List[A]]): List[A] = {
    def loop[A](acum: List[A], ls: List[List[A]]): List[A] = ls match {
      case Cons(x, xs) => loop(append(acum, x), xs)
      case Nil => acum
    }
    loop(List(), l)
  }

  def toString(l: List[Double]): String =
    foldRight(l, "")(_.toString + ", " + _)

  def increaseElems(l: List[Int]): List[Int] =
    foldRight(l, List(): List[Int])((i, l) => Cons(i + 1, l))

  def map[A, B](as: List[A])(f: A => B): List[B] = {
    def loop(l: List[A], res: List[B]): List[B] = l match {
      case Nil => res
      case Cons(x, xs) => loop(xs, append(res, List(f(x))))
    }
    loop(as, List(): List[B])
  }

  def filter[A](l: List[A])(f: A => Boolean): List[A] = l match {
    case Nil => Nil
    case Cons(x, xs) if f(x) => Cons(x, filter(xs)(f))
    case Cons(x, xs) if !f(x) => filter(xs)(f)
  }

  def flatMap[A, B](as: List[A])(f: A => List[B]): List[B] = {
    def loop(l: List[A], res: List[B]): List[B] = l match {
      case Nil => res
      case Cons(x, xs) => loop(xs, append(res, f(x)))
    }
    loop(as, List())
  }

  def empty[A](l: List[A]): Boolean = l match {
    case Nil => true
    case _ => false
  }

  def filter2[A](l: List[A])(f: A => Boolean) =
    flatMap(l)((a) => if (f(a)) List(a) else Nil)

  def sumLists(l1: List[Int], l2: List[Int]): List[Int] = l1 match {
    case Cons(x, xs) if !empty(l2) => Cons(x + head(l2), sumLists(xs, tail(l2)))
    case _ => Nil
  }

  def zipWith[A](l1: List[A], l2: List[A])(f: (A, A) => A): List[A] = l1 match {
    case Cons(x, xs) if !empty(l2) => Cons(f(x, head(l2)), zipWith(xs, tail(l2))(f))
    case _ => Nil
  }

  def hasSubsequence[A](sup: List[A], sub: List[A]): Boolean = {
    def check(l: List[A], s: List[A]): Boolean = l match {
      case Cons(x, xs) if !empty(s) => if (head(s) == x) check(xs, tail(s)) else false
      case _ if empty(s) => true
      case _ => false
    }
    sup match {
      case l @ Cons(x, xs) if length(l) >= length(sub) => if (check(l, sub)) true else hasSubsequence(xs, sub)
      case _ => false
    }
  }
}