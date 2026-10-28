#include <assert.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
int main(void) {
  for (int pass = 0; pass < 100; ++pass) {
    struct addrinfo hints = {0}, *result = 0;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICHOST | AI_CANONNAME;
    assert(getaddrinfo("127.0.0.1", "13384", &hints, &result) == 0);
    assert(result && result->ai_family == AF_INET && result->ai_next == 0);
    assert(result->ai_canonname && strcmp(result->ai_canonname, "127.0.0.1") == 0);
    freeaddrinfo(result);
    hints.ai_flags = AI_PASSIVE;
    assert(getaddrinfo(0, "13384", &hints, &result) == 0);
    assert(result && result->ai_canonname == 0 && result->ai_next == 0);
    freeaddrinfo(result);
  }
  puts("PASS: wasm64 numeric/canonical and passive address resolution");
}
