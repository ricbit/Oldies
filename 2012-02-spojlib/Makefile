GTEST_DIR=/home/ricbit/src/gtest-1.6.0
all: matrix_test modint_test
matrix_test : matrix_test.cc matrix.h
	g++ -static -I${GTEST_DIR}/include -L${GTEST_DIR}/lib/.libs matrix_test.cc -o matrix_test -lgtest -lgtest_main -lpthread -Wall
modint_test : modint_test.cc modint.h
	g++ -static -I${GTEST_DIR}/include -L${GTEST_DIR}/lib/.libs modint_test.cc -o modint_test -lgtest -lgtest_main -lpthread -Wall
