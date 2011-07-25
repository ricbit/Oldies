# ZenoReduce
# Ricardo Bittencourt 2010

import os

class TimerAdapter(object):
  def __init__(self, timer=lambda:os.times()[0]):
    self.timer = timer

  def time(self):
    return self.timer()


class TimeInterval(object):
  def __init__(self, timer=TimerAdapter()):
    self.timer = timer

  def begin(self):
    self.elapsed = 0
    self.start = self.timer.time()

  def end(self):
    self.update()

  def add(self, amount):
    self.elapsed += amount

  def total(self):
    return self.elapsed

  def pause(self):
    self.update()

  def restart(self):
    self.start = self.timer.time()

  def update(self):
    self.add(self.timer.time() - self.start)


class TimeIntervalProvider(object):
  def get(self):
    return TimeInterval()


class NoContextAvailable(Exception):
  def __str__(self):
    return "Please run zenoreduce inside a zeno.run()"


class ContextManager(object):
  def __init__(self, provider=TimeIntervalProvider()):
    self.provider = provider
    self.context = None

  def start(self):
    self.context = [self.provider.get()]

  def get(self):
    if self.context is not None:
      return self.context[0]
    else:
      raise NoContextAvailable()

  def push(self):
    self.context.insert(0, self.provider.get())
    return self.context[0]

  def pop(self):
    self.context.pop(0)

  def close(self):
    self.context = None


class Runner(object):
  def __init__(self, manager=ContextManager(), provider=TimeIntervalProvider()):
    self.manager = manager
    self.provider = provider

  def run(self, code):
    self.manager.start()
    walltime = self.provider.get()
    interval = self.manager.get()
    walltime.begin()
    interval.begin()
    result = code()
    interval.end()
    walltime.end()
    self.manager.close()
    return (result, walltime.total(), interval.total())

  def zenoreduce(self, binary_op, elements, initial):
    outer = self.manager.get()
    outer.pause()
    inner = self.manager.push()
    result = initial
    iterator = enumerate(elements)
    try:
      while True:
        inner.begin()
        i,elem = iterator.next()
        result = binary_op(result, elem)
        inner.end()
        try:
          outer.add(inner.total() / 2.0**i)
        except OverflowError:
          pass
    except StopIteration:
      pass
    self.manager.pop()
    outer.restart()
    return result


runner_singleton = Runner()

def zenoreduce(binary_op, elements, initial):
  return runner_singleton.zenoreduce(binary_op, elements, initial)
  
def run(program):
  return runner_singleton.run(program)
  