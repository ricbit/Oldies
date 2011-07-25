# ZenoReduce, unit tests
# Ricardo Bittencourt 2010

import zeno

import mox
import unittest

class TimerAdapterTest(unittest.TestCase):
  def testTimer(self):
    adapter = zeno.TimerAdapter(timer=lambda:12345)
    assert adapter.timer() == 12345
    

class TimeIntervalTest(unittest.TestCase):
  def setUp(self):
    self.control = mox.Mox()
    self.timer = self.control.CreateMock(zeno.TimerAdapter)
    self.time_interval = zeno.TimeInterval(timer=self.timer)
    
  def testSimplePipeline(self):
    self.timer.time().AndReturn(3)
    self.timer.time().AndReturn(5)
    self.control.ReplayAll()
    
    self.time_interval.begin()
    self.time_interval.end()
    
    self.control.VerifyAll()
    assert self.time_interval.total() == 2

  def testPipelineCalledTwice(self):
    self.timer.time().AndReturn(3)
    self.timer.time().AndReturn(5)
    self.timer.time().AndReturn(10)
    self.timer.time().AndReturn(13)
    self.control.ReplayAll()
    
    self.time_interval.begin()
    self.time_interval.end()
    assert self.time_interval.total() == 2
    self.time_interval.begin()
    self.time_interval.end()
    assert self.time_interval.total() == 3    
    self.control.VerifyAll()
    
  def testPipelineWithPause(self):
    self.timer.time().AndReturn(3)
    self.timer.time().AndReturn(5)
    self.timer.time().AndReturn(10)
    self.timer.time().AndReturn(13)
    self.control.ReplayAll()
    
    self.time_interval.begin()
    self.time_interval.pause()
    self.time_interval.restart()
    self.time_interval.end()
    assert self.time_interval.total() == 5
    self.control.VerifyAll()
    
  def testPipelineWithAdd(self):
    self.timer.time().AndReturn(3)
    self.timer.time().AndReturn(5)
    self.control.ReplayAll()
    
    self.time_interval.begin()
    self.time_interval.end()
    self.time_interval.add(5)
    
    self.control.VerifyAll()
    assert self.time_interval.total() == 7
    
    
class TimeIntervalProviderTest(unittest.TestCase):
  def setUp(self):
    self.provider = zeno.TimeIntervalProvider()
    
  def testGet(self):
    timer = self.provider.get()
    assert isinstance(timer, zeno.TimeInterval)
    
  def testGetDifferentInstanceEachTime(self):
    first = self.provider.get()
    second = self.provider.get()
    assert first is not second    
    
    
class ContextManagerTest(unittest.TestCase):
  def setUp(self):
    self.control = mox.Mox()
    self.provider = self.control.CreateMock(zeno.TimeIntervalProvider)
    self.context_manager = zeno.ContextManager(provider=self.provider)
    
  def testContextManager(self):
    interval_a = self.control.CreateMock(zeno.TimeInterval)
    interval_b = self.control.CreateMock(zeno.TimeInterval)
    interval_c = self.control.CreateMock(zeno.TimeInterval)
    self.provider.get().AndReturn(interval_a)
    self.provider.get().AndReturn(interval_b)
    self.provider.get().AndReturn(interval_c)
    self.control.ReplayAll()
    
    self.context_manager.start()
    assert interval_a is self.context_manager.get()
    self.context_manager.push()
    assert interval_b is self.context_manager.get()
    self.context_manager.push()
    assert interval_c is self.context_manager.get()
    self.context_manager.pop()
    assert interval_b is self.context_manager.get()
    self.context_manager.pop()
    assert interval_a is self.context_manager.get()
    self.control.VerifyAll()
    
  def testGetBeforeStartRaisesException(self):
    try:
      self.context_manager.get()
      assert False
    except zeno.NoContextAvailable:
      pass
    
  def testGetAfterCloseRaisesException(self):
    self.provider.get().AndReturn(self.control.CreateMock(zeno.TimeInterval))
    self.context_manager.start()
    self.context_manager.close()
    try:
      self.context_manager.get()
      assert False
    except zeno.NoContextAvailable:
      pass
    

class RunnerTest(unittest.TestCase):
  def setUp(self):
    self.control = mox.Mox()
    self.timer = self.control.CreateMock(zeno.TimerAdapter)
    self.walltimer = self.control.CreateMock(zeno.TimerAdapter)
    self.walltime_provider = self.control.CreateMock(zeno.TimeIntervalProvider)    
    self.provider = self.control.CreateMock(zeno.TimeIntervalProvider)    
    self.context_manager = zeno.ContextManager(provider=self.provider)
    self.runner = zeno.Runner(manager=self.context_manager, provider=self.walltime_provider)

  def testRun(self):
    self.walltime_provider.get().AndReturn(zeno.TimeInterval(timer=self.walltimer))
    self.provider.get().AndReturn(zeno.TimeInterval(timer=self.timer))
    self.timer.time().AndReturn(2)
    self.timer.time().AndReturn(5)
    self.walltimer.time().AndReturn(1)
    self.walltimer.time().AndReturn(6)
    self.code_executed = False
    def mockCode():
      self.code_executed = True
      return 42
    self.control.ReplayAll()
    
    assert (42, 5, 3) == self.runner.run(mockCode)
    assert self.code_executed
    self.control.VerifyAll()

  def testZenoReduce(self):
    self.walltime_provider.get().AndReturn(zeno.TimeInterval(timer=self.walltimer))
    self.walltimer.time().AndReturn(0)
    self.walltimer.time().AndReturn(12)
    outer = zeno.TimeInterval(timer=self.timer)
    inner = zeno.TimeInterval(timer=self.timer)
    self.provider.get().AndReturn(outer)
    self.provider.get().AndReturn(inner)
    for i in xrange(13):
      self.timer.time().AndReturn(i)
    self.code_executed = False
    def mockCode():
      self.code_executed = True
      assert 6 == self.runner.zenoreduce(lambda x,y: x+y, range(4), 0)
      return 42
    self.control.ReplayAll()
    
    expected = 2 + 1 + 1./2 + 1./4 + 1./8
    eps = 1e-6
    result, wall, user = self.runner.run(mockCode)
    assert 42 == result
    assert 12 == wall
    assert abs(expected - user) < eps
    assert self.code_executed
    self.control.VerifyAll()
    
  def testZenoReduceNested(self):
    self.walltime_provider.get().AndReturn(zeno.TimeInterval(timer=self.walltimer))
    self.walltimer.time().AndReturn(0)
    self.walltimer.time().AndReturn(20)
    outer = zeno.TimeInterval(timer=self.timer)
    medium = zeno.TimeInterval(timer=self.timer)
    inner = zeno.TimeInterval(timer=self.timer)
    self.provider.get().AndReturn(outer)
    self.provider.get().AndReturn(medium)
    self.provider.get().AndReturn(inner)
    self.provider.get().AndReturn(inner)
    for i in xrange(23):
      self.timer.time().AndReturn(i)
    self.code_executed = False
    def inner(k):
      result = self.runner.zenoreduce(lambda x,y: x+y, range(2), 0)
      assert 1 == result
      return result
    def mockCode():
      self.code_executed = True
      assert 2 == self.runner.zenoreduce(lambda x,y: x+inner(y), range(2), 0)
      return 42
    self.control.ReplayAll()
    
    expected = 2 + 3 + 1./2 + 1./2*(3 + 1./2)
    eps = 1e-6
    result, wall, user = self.runner.run(mockCode)
    assert 42 == result
    assert 20 == wall
    assert abs(expected - user) < eps
    assert self.code_executed
    self.control.VerifyAll()
    
  def testZenoReduceRaisesExceptionOutsideRun(self):
    try:
      zeno.zenoreduce(lambda x,y:x+y, [1,2], 0)
      assert False
    except zeno.NoContextAvailable:
      pass
      
  def testWiringOfSingleton(self):
    result, wall, user = zeno.run(lambda:zeno.zenoreduce(lambda x,y: x+y, [1,2,3], 0))
    assert 6 == result
    assert wall >= user >= 0.0
    
  def testZenoReduceWith2000Iterations(self):
    result, wall, user = zeno.run(lambda:zeno.zenoreduce(lambda x,y: x+1, xrange(2000), 0))
    assert 2000 == result
    assert wall >= user >= 0.0
      

if __name__ == "__main__":
  unittest.main()
        