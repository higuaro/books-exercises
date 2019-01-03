package fpinscala.lazyness

sealed trait Stream[+A] {
  def toList: List[A] = {
    def loop(res: List[A], s: Stream[A]): List[A] = s match {
      case Empty => res
      case Cons(h, t) => loop(res :+ h(), t())
    }
    loop(List.empty, this)
  }

  def take(n: Int): Stream[A] = {
    def loop(ss: Stream[A], n: Int): Stream[A] = ss match {
      case Cons(h, t) => if (n == 0) Empty else Stream.cons(h(), loop(t(), n - 1))
      case _ => Empty
    }
    loop(this, n)
  }

  def takeWhile(p: A => Boolean): Stream[A] = {
    def loop(ss: Stream[A]): Stream[A] = ss match {
      case Cons(h, t) => if (p(h())) Stream.cons(h(), loop(t())) else Empty
      case _ => Empty
    }
    loop(this)
  }

  def takeWhile2(p: A => Boolean): Stream[A] =
    foldRight(Stream.empty: Stream[A])({ (elem, accum) => if (p(elem)) Stream.cons(elem, accum) else Stream.empty })

  //  x < 4
  //  1,  2,  3, 4, 5
  //  1 ? (2 ? (3 ? (4 ? 5)))

  def drop(n: Int): Stream[A] = {
    def loop(ss: Stream[A], n: Int): Stream[A] = ss match {
      case Cons(h, t) => if (n == 0) ss else loop(t(), n - 1)
      case _ => Empty
    }
    loop(this, n)
  }

  def foldRight[B](z: => B)(f: (A, => B) => B): B = this match {
    case Cons(h, t) => f(h(), {
      t().foldRight(z)(f)
    })
    case _ => z
  }

  def forAll(p: A => Boolean): Boolean =
    foldRight(true)((a, b) => p(a) && b)

  def headOption(): Option[A] =
    foldRight(None: Option[A])((elem, _) => Some(elem))

  def map[B](f: A => B): Stream[B] =
    foldRight(Stream.empty: Stream[B])((elem, accum) => Stream.cons(f(elem), accum))

  def filter(f: A => Boolean): Stream[A] =
    foldRight(Stream.empty: Stream[A])((elem, accum) => if (f(elem)) Stream.cons(elem, accum) else accum)

  def append[B >: A](other: => Stream[B]): Stream[B] =
    foldRight(other)((elem, accum) => Stream.cons(elem, accum))

  def find(f: A => Boolean): Option[A] =
    filter(f).headOption()

  def exists(f: A => Boolean): Boolean =
    foldRight(false)((h, t) => if (f(h)) true else t)

  def flatMap[B >: A](f: B => Stream[B]): Stream[B] =
    foldRight(Stream.empty: Stream[B])((elem, accum) => f(elem) append accum)

  def mapU[B](f: A => B): Stream[B] =
    Stream.unfold(this) {
      (s: Stream[A]) => s match {
        case Cons(h, t) => Some(f(h()), t())
        case _ => None
      }
    }

  def takeU(n: Int): Stream[A] =
    Stream.unfold(0 -> this) {
      (s: (Int, Stream[A])) => if (s._1 < n) s._2 match {
        case Cons(h, t) => Some(h(), s._1 + 1 -> t())
        case _ => None
      }
      else None
    }

  def takeWhileU(p: A => Boolean): Stream[A] =
    Stream.unfold(this) {
      (s: Stream[A]) => s match {
        case Cons(h, t) if p(h()) => Some(h(), t())
        case _ => None
      }
    }

  def zipWith[B >: A](other: Stream[B])(f: (B, B) => B): Stream[B] =
    Stream.unfold((this: Stream[B], other)) {
      (s: (Stream[B], Stream[B])) => s match {
        case (Cons(h1, t1), Cons(h2, t2)) => Some(f(h1(), h2()) -> (t1(), t2()))
        case _ => None
      }
    }

  def zipAll[B](other: Stream[B]): Stream[(Option[A], Option[B])] =
    Stream.unfold((this, other)) {
      (s: (Stream[A], Stream[B])) => s match {
        case (Cons(h1, t1), Cons(h2, t2)) => Some((Some(h1()), Some(h2())) -> (t1(), t2()))
        case (Empty, Cons(h2, t2)) => Some((None, Some(h2())) -> (Stream.empty, t2()))
        case (Cons(h1, t1), Empty) => Some((Some(h1()), None) -> (t1(), Stream.empty))
        case _ => None
      }
    }

  def startsWith[B >: A](s: Stream[B]): Boolean =
    Stream.unfold((this: Stream[B], s)) {
      (s: (Stream[B], Stream[B])) => s match {
        case (Cons(h1, t1), Cons(h2, t2)) => if (h1() == h2()) Some(true -> (t1(), t2())) else Some(false -> (Stream.empty, Stream.empty))
        case _ => None
      }
    }.find(_ == false).isEmpty

  def tails: Stream[Stream[A]] =
    Stream.unfold(this) {
      (s: Stream[A]) => s match {
        case ss @ Cons(h, t) => Some(ss -> t())
        case _ => None
      }
    }

  def scanRight[B](z: => B)(f: (A, => B) => B): Stream[B] = {
    Stream.unfold(this) {
      (s: Stream[A]) => s match {
        case ss @ Cons(h, t) => Some(ss.foldRight(z)(f) -> t())
        case _ => None
      }
    }.append(Stream(z))
  }
}

case object Empty extends Stream[Nothing]
case class Cons[+A](h: () => A, t: () => Stream[A]) extends Stream[A]

object Stream {
  def cons[A](hd: => A, tl: => Stream[A]): Stream[A] = {
    lazy val head = hd
    lazy val tail = tl
    Cons(() => head, () => tail)
  }

  def unfold[A, S](z: S)(f: S => Option[(A, S)]): Stream[A] = {
    lazy val state = f(z)
    state match {
      case Some((aa, ss)) => Stream.cons(aa, unfold(ss)(f))
      case None => Stream.empty
    }
  }

  def empty[A]: Stream[A] = Empty

  def constant[A](a: A): Stream[A] =
    Stream.cons(a, constant(a))

  def from(n: Int): Stream[Int] =
    cons(n, from(n + 1))

  def fibs: Stream[Int] = {
    def fib(n1: Int, n2: Int): Stream[Int] =
    Stream.cons(n1, fib(n2, n1 + n2))
    fib(0, 1)
  }

  def onesU: Stream[Int] =
    unfold(1)(s => Some((1, 1)))

  def constantU(n: Int): Stream[Int] =
    unfold(n)(s => Some((n, n)))

  def fromU(n: Int): Stream[Int] =
    unfold(n)(s => Some((s, s + 1)))

  def fibsU: Stream[Int] =
    unfold((0, 1))((s: (Int, Int)) =>
      Some(s._1 -> (s._2, s._1 + s._2))
    )

  def apply[A](as: A*): Stream[A] =
    if (as.isEmpty) empty else cons(as.head, apply(as.tail: _*))
}
