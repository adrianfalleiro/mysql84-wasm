#include "my_timer.h"
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <mutex>

struct TestTimer {
  my_timer_t timer;
  std::mutex mutex;
  std::condition_variable changed;
  int fired = 0;
  bool delete_in_callback = false;
  bool block_callback = false;
  bool entered = false;
  bool release = false;
};
static void notify(my_timer_t *timer) {
  auto *test = reinterpret_cast<TestTimer *>(timer);
  std::unique_lock<std::mutex> lock(test->mutex);
  if (test->block_callback) {
    test->entered = true;
    test->changed.notify_all();
    test->changed.wait(lock, [&] { return test->release; });
  }
  if (test->delete_in_callback) my_timer_delete(timer);
  ++test->fired;
  test->changed.notify_all();
}
static void create(TestTimer &test) {
  test.timer.notify_function = notify;
  assert(my_timer_create(&test.timer) == 0);
}
static void await_count(TestTimer &test, int count) {
  std::unique_lock<std::mutex> lock(test.mutex);
  assert(test.changed.wait_for(lock, std::chrono::seconds(5), [&] { return test.fired == count; }));
}
int main() {
  for (int cycle = 0; cycle < 2; ++cycle) {
    assert(my_timer_initialize() == 0);
    TestTimer first, cancelled, self_delete;
    create(first); create(cancelled); create(self_delete);
    int state = -1;
    assert(my_timer_set(&cancelled.timer, 600000) == 0);
    assert(my_timer_cancel(&cancelled.timer, &state) == 0 && state == 1);
    assert(my_timer_set(&first.timer, 600000) == 0);
    assert(my_timer_set(&first.timer, 5) == 0);
    await_count(first, 1);
    assert(my_timer_cancel(&first.timer, &state) == 0 && state == 0);
    assert(my_timer_set(&first.timer, 5) == 0);
    await_count(first, 2);
    self_delete.delete_in_callback = true;
    assert(my_timer_set(&self_delete.timer, 5) == 0);
    await_count(self_delete, 1);
    assert(self_delete.timer.id == nullptr);
    assert(cancelled.fired == 0);
    TestTimer racing;
    create(racing);
    racing.block_callback = true;
    assert(my_timer_set(&racing.timer, 1) == 0);
    {
      std::unique_lock<std::mutex> lock(racing.mutex);
      assert(racing.changed.wait_for(lock, std::chrono::seconds(5), [&] { return racing.entered; }));
      assert(my_timer_cancel(&racing.timer, &state) == 0 && state == 0);
      racing.release = true;
      racing.changed.notify_all();
    }
    await_count(racing, 1);
    my_timer_delete(&racing.timer);
    my_timer_delete(&first.timer);
    my_timer_delete(&cancelled.timer);
    my_timer_deinitialize();
  }
  puts("PASS: wasm64 timer expiry, cancel, rearm, reuse, callback deletion, reinitialization");
}
