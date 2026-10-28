#include <atomic>
#include <cassert>
#include <cerrno>
#include <cstdio>
#include <pthread.h>
#include <signal.h>
#include <emscripten/threading.h>
static std::atomic<bool> ready{false};
static void *waiter(void *) {
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGUSR1);
  assert(pthread_sigmask(SIG_BLOCK, &set, nullptr) == 0);
  siginfo_t info;
  assert(sigwaitinfo(&set, &info) == -1 && errno == EINVAL);
  ready = true;
  int result;
  while ((result = sigwaitinfo(&set, &info)) == -1 &&
         (errno == EINTR || errno == EINVAL)) {
    emscripten_thread_sleep(10);
  }
  assert(result == SIGUSR1 && info.si_signo == SIGUSR1);
  return nullptr;
}
int main() {
  pthread_t thread;
  assert(pthread_create(&thread, nullptr, waiter, nullptr) == 0);
  while (!ready) emscripten_thread_sleep(1);
  assert(pthread_kill(thread, SIGUSR1) == 0);
  assert(pthread_join(thread, nullptr) == 0);
  puts("PASS: Emscripten sigwaitinfo gap reproduced; mailbox-aware retry receives pthread signal");
}
