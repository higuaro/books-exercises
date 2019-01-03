package fpinscala.errorhandling

sealed trait Either[+E, +A] {
  def map[B](f: A => B): Either[E, B] = this match {
    case Right(a) => Right(f(a))
    case Left(e) => Left(e)
  }

  def flatMap[EE >: E, B](f: A => Either[EE, B]): Either[EE, B] = this match {
    case Right(a) => f(a)
    case Left(e) => Left(e)
  }

  def orElse[EE >: E, B >: A](b: => Either[EE, B]): Either[EE, B] =
    if (isRight) this else b

  def isRight: Boolean = this match {
    case Right(_) => true
    case _ => false
  }

  def map2[EE >: E, B, C](b: Either[EE, B])(f: (A, B) => C): Either[EE, C] =
    // flatMap(a => b.map(b => f(a, b)))
    for (a <- this; bb <- b) yield f(a, bb)
}

object Either {
  def sequence[E, A](es: List[Either[E, A]]): Either[E, List[A]] =
    traverse(es){ a => a }

  def traverse[E, A, B](as: List[A])(f: A => Either[E, B]): Either[E, List[B]] = {
    def loop(as: List[A], res: List[B]): Either[E, List[B]] = as match {
      case Nil => Right(res)
      case x :: xs => {
        val fx = f(x)
        fx match {
          case Right(a) => loop(xs, res :+ a)
          case Left(e) => Left(e)
        }
      }
      // case h :: t => f(h) flatMap { a => loop(t, res :+ a) }
      //      case h :: t => f(h) map2 traverse(t)(f) {_ :: _}
    }
    loop(as, List.empty : List[B])
  }
}

case class Left[+E](value: E) extends Either[E, Nothing]
case class Right[+A](value: A) extends Either[Nothing, A]