package coursera

object Week1 {
  /**
    * Exercise 1
    */
  def pascal(r: Int, c: Int): Int = {
    if (c <= 0 || c >= r) return 1
    if (c == 1 || c == r - 1) return r
    pascal(r - 1, c - 1) + pascal(r - 1, c)
  }

  /**
    * Exercise 2
    */
  def balance(chars: List[Char]): Boolean = {
    def loop(chars: List[Char], parenthesisCount: Int): Boolean = {
      if (chars.isEmpty) return parenthesisCount == 0
      if (parenthesisCount < 0) return false
      val h = chars.head
      val delta = if (h == '(') 1 else if (h == ')') -1 else 0
      loop(chars.tail, parenthesisCount + delta)
    }
    loop(chars, 0)
  }

  /**
    * Exercise 3
    */
  def countChange(money: Int, coins: List[Int]): Int = {
    def loop(money: Int, coins: List[Int]): Int = {
      if (coins.isEmpty) return 0
      count(money, coins) + loop(money, coins.tail)
    }
    def count(money: Int, coins: List[Int]): Int = {
      if (coins.isEmpty || (money - coins.head) < 0) return 0
      if ((money - coins.head) == 0) return 1
      count(money - coins.head, coins.tail) + count(money - coins.head, coins)
    }
    loop(money, coins)
  }
}
