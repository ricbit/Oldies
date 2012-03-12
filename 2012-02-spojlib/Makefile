GTEST_DIR=/home/ricbit/src/gtest-1.6.0
all: matrix_test modint_test bigint_test io_test
matrix_test : matrix_test.cc matrix.h
	g++ -static -I${GTEST_DIR}/include -L${GTEST_DIR}/lib/.libs matrix_test.cc -o matrix_test -lgtest -lgtest_main -lpthread -Wall
modint_test : modint_test.cc modint.h
	g++ -static -I${GTEST_DIR}/include -L${GTEST_DIR}/lib/.libs modint_test.cc -o modint_test -lgtest -lgtest_main -lpthread -Wall
bigint_test : bigint_test.cc bigint.h
	g++ -static -I${GTEST_DIR}/include -L${GTEST_DIR}/lib/.libs bigint_test.cc -o bigint_test -lgtest -lgtest_main -lpthread -Wall
io_test : io_test.cc io.h
	g++ -static -I${GTEST_DIR}/include -L${GTEST_DIR}/lib/.libs io_test.cc -o io_test -lgtest -lgtest_main -lpthread -Wall
