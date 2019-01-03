#include <iostream>
#include <string>

void move(int n, char s, char d, char t) {
    using std::cout;
    const std::string to(" -> ");
    if (n == 1) {
        cout << s << to << d << "\n";
        return;
    }
    
    if (n == 2) {
        cout << s << to << t << "\n";
        cout << s << to << d << "\n";
        cout << t << to << d << "\n";
        return;
    }
    
    move(n - 1, s, t, d);
    std::cout << s << to << d << "\n";
    move(n - 1, t, d, s);
}

int main() {
    move(4, '1', '3', '2');
    return 0;
}
