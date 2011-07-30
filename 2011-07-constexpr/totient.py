import os
import subprocess

MAX_RECURSION = 100000

def timer():
  return os.times()[-1]

def measure(source, number):
  start_compiling = timer()
  gcc = ["g++", "-O3", "-ototient", "-ftemplate-depth-%s" % str(MAX_RECURSION),
         "-fconstexpr-depth=%s" % str(MAX_RECURSION), "-DNUMBER=%s" % number,
         "-std=c++0x", source]
  subprocess.call(gcc)
  end_compiling = timer()
  subprocess.call("./totient")
  end_run = timer()
  return (end_compiling - start_compiling), (end_run - end_compiling)

def plot(source):
  numbers = range(500, 30000, 500)
  ans = []
  for number in numbers:
    compile_time, run_time = measure(source, number)
    ans.append((number, compile_time, run_time))
  return ans

sources = ["totient_runtime.cc", "totient_template.cc", "totient_constexpr.cc"]
for source in sources:
  ans = plot(source)
  print source
  print ans
