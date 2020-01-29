#include <bits/stdc++.h>
using namespace std;
int edit_dist_dp(const string& s1, const string& s2) {
  const int N = s1.size() + 1;
  const int M = s2.size() + 1;
  vector<vector<int>> t(N, vector<int>(M, 0));
  for (int i = 0; i < N; i++) t[i][0] = i;
  for (int i = 0; i < M; i++) t[0][i] = i;
  for (int i = 1; i < N; i++) {
    for (int j = 1; j < M; j++) {
      int ins = t[i - 1][j] + 1;
      int del = t[i][j - 1] + 1;
      int edi = t[i - 1][j - 1] + (s1[i] != s2[j]);
      t[i][j] = min(min(ins, del), edi);
    }
  }
  return t[N - 1][M - 1];
}
map<pair<int, int>, int> memo;
int edit_dist_memo(const string& s1, const string& s2,
    int a = 0, int b = 0) {
  auto t = make_pair(a, b);
  if (memo.count(t)) return memo[t];

  if (a >= static_cast<int>(s1.size())) return s2.size() - b;
  if (b >= static_cast<int>(s2.size())) return s1.size() - a;

  int ins, del, edi; ins = del = edi = 0;
  ins = edit_dist_memo(s1, s2, a, b + 1) + 1;
  del = edit_dist_memo(s1, s2, a + 1, b) + 1;
  edi = edit_dist_memo(s1, s2, a + 1, b + 1) + (s1[a] != s2[b]);

  return (memo[t] = min(min(ins, del), edi));
}
int edit_dist_recur(const string& s1, const string& s2) {
  if (s1.empty()) return s2.size();
  if (s2.empty()) return s1.size();

  int ins, del, edi; ins = del = edi = 0;
  ins = edit_dist_recur(s1, s2.substr(1)) + 1;
  del = edit_dist_recur(s1.substr(1), s2) + 1;
  edi = edit_dist_recur(s1.substr(1), s2.substr(1)) + (s1[0] != s2[0]);

  return min(min(ins, del), edi);
}
int main() {
  ios_base::sync_with_stdio(false);
  cin.tie(nullptr);

  // const int N = 10;
  // vector<vector<int>> t(N, vector<int>(N, 0));

  string s1; cin >> s1;
  string s2; cin >> s2;

  cout << edit_dist_memo(s1, s2) << endl;
  cout << edit_dist_recur(s1, s2) << endl;
  return 0;
}
