package fpinscala.errorhandling

object Misc {
  def mean(l: Seq[Double]): Option[Double] =
    if (l.isEmpty)
      None()
    else
      Some(l.foldRight(0.0)((a, v) => a + v) / l.size)

  def variance_1(l: Seq[Double]): Option[Double] = {
    lazy val m = mean(l)
    mean(l.map(v => math.pow(v - m.getOrElse(0.0), 2)))
  }

  def variance(l: Seq[Double]): Option[Double] =
    mean(l).flatMap(m => mean(l.map(x => math.pow(x - m, 2))))
}