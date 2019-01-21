all : example

stuff_serial.cc : stuff.h serialize.py
	python serialize.py stuff.h stuff_serial.cc

example : example.cc stuff.h stuff_serial.cc save.h
	g++ -std=c++11 example.cc stuff_serial.cc -o example -O3 -Wall
