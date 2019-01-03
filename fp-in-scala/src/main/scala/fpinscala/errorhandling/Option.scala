package fpinscala.errorhandling

sealed trait Option[+A] {
  def map[B](f: A => B): Option[B] = this match {
    case Some(a) => Some(f(a))
    case _ => None()
  }


  def flatMap[B](f: A => Option[B]): Option[B] = this.map(f).getOrElse(None())

  def getOrElse[B >: A](default: => B): B = this match {
    case Some(a) => a
    case _ => default
  }

  def isPresent: Boolean = this match {
    case Some(_) => true
    case _ => false
  }

  def orElse[B >: A](obj: => Option[B]): Option[B] = this map(Some(_)) getOrElse obj

  def filter(f: A => Boolean): Option[A] = this flatMap(a => if (f(a)) Some(a) else None())
}

case class Some[+A](some: A) extends Option[A]
case class None() extends Option[Nothing]

object Option {
  def map2[A, B, C](optA: Option[A], optB: Option[B])(f: (A, B) => C): Option[C] =
    optA flatMap(a => optB map(b => f(a, b)))

  def map2_1[A, B, C](optA: Option[A], optB: Option[B])(f: (A, B) => C): Option[C] = {
    def g(a: A): B => C = f(a, _)
    optA.map(a => g(a)).flatMap(g => optB.map(b => g(b)))
  }

  // for comprehensions are not allowed here
  def sequence[A](l: List[Option[A]]): Option[List[A]] = {
    def loop(ls: List[Option[A]], res: List[A]): Option[List[A]]  = ls match {
      case Nil => Some(Nil)
      case Some(v) :: Nil => Some(res :+ v)
      case Some(v) :: xs => loop(xs, res :+ v)
      case None() :: _ => None()
    }

    loop(l, List.empty)
  }

  def sequence_1[A](l: List[Option[A]]): Option[List[A]] =
    l match {
      case Nil => Some(Nil)
      case h :: t => h flatMap(hh => sequence_1(t) map (hh :: _))
    }

  def sequence_2[A](l: List[Option[A]]): Option[List[A]] =
    l.foldRight[Option[List[A]]](Some(Nil))((x, y) =>  map2(x, y)(_ :: _))

  def traverse[A, B](l: List[A])(f: A => Option[B]): Option[List[B]] = {
    def loop(ls: List[A], res: List[B]): Option[List[B]] = ls match {
      case Nil => Some(res)
      case x :: xs => f(x) flatMap { b => loop(xs, res :+ b) }
    }
    loop(l, List.empty)
  }

  def sequence_t[A](l: List[Option[A]]): Option[List[A]] =
    traverse(l) { a => a }

}