#include <openssl/sha.h>
#include <openssl/rand.h>
#include <openssl/ssl.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
int main(void) {
  unsigned char digest[32], random_a[32], random_b[32];
  char text[65];
  assert(SHA256((const unsigned char *)"abc", 3, digest));
  for (int i = 0; i < 32; ++i) sprintf(text + 2*i, "%02x", digest[i]);
  assert(strcmp(text, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") == 0);
  assert(RAND_bytes(random_a, sizeof random_a) == 1);
  assert(RAND_bytes(random_b, sizeof random_b) == 1);
  assert(memcmp(random_a, random_b, sizeof random_a) != 0);
  SSL_CTX *context = SSL_CTX_new(TLS_server_method());
  assert(context);
  SSL_CTX_free(context);
  puts("PASS: wasm64 OpenSSL SHA256, secure random, TLS server context");
}
