#include <iostream>
#include <string>
#include <unordered_map>
#include <map>
#include <set>

using namespace std;
typedef tuple<int, int, int> ttt;
set<ttt> memo;
set<ttt> found;

void solve(int _3, int _5, int _10, int n) {
  ttt t = make_tuple(_3, _5, _10);
  if (memo.count(t)) {
    cerr << "hit memo ";
    cerr << _3 << ' ' << _5 << ' ' << _10 << endl;
  }
  memo.insert(t);

  int score = _3 * 3 + _5 * 5 + _10 * 10;
  if (score > n) return;
  if (score == n) {
    cerr << "Found " << _3 << ' ' << _5 << ' ' << _10 << endl;
    found.insert(t);
    return;
  }
  solve(_3 + 1, _5, _10, n);
  solve(_3, _5 + 1, _10, n);
  solve(_3, _5, _10 + 1, n);
}

int main() {
  std::ios_base::sync_with_stdio(false);
  cin.tie(nullptr);
  int n; cin >> n;
  solve(0, 0, 0, n);
  cout << found.size() << std::endl;
  return 0;
}
