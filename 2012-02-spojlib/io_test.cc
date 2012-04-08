#include <string>
#include <cstring>
#include "gtest/gtest.h"
#include "io.h"

using namespace std;

template<const char *input>
class MemoryStdio {
 public:
  MemoryStdio() : input_(input) {}

  static string& get() {
    return output_;
  }

  int read(char* input_buffer, int size) {
    string sub = input_.substr(pos_, size);
    strcpy(input_buffer, sub.c_str());
    pos_ += sub.size();
    return sub.size();
  }

  void write(char* output_buffer, int size) {
    output_.append(output_buffer, size);
  }

  string input_;
  static int pos_;
  static string output_;
};

template<const char *input> int MemoryStdio<input>::pos_ = 0;
template<const char *input> string MemoryStdio<input>::output_ = "";

#define TEST_IO(name, size, buf, str) \
  extern const char input_##name[] = str; \
  typedef MemoryStdio<input_##name> out_##name; \
  typedef _fastio<size, buf, out_##name> fastio_##name; \
  TEST(IoTest, name)

TEST_IO(ReadInt, 200, 30, "1 12345 -1 -12345 123456789012345") {
  fastio_ReadInt io;
  EXPECT_EQ(1U, static_cast<unsigned int>(io));
  EXPECT_EQ(12345U, static_cast<unsigned int>(io));
  EXPECT_EQ(-1, static_cast<int>(io));
  EXPECT_EQ(-12345, static_cast<int>(io));
  EXPECT_EQ(123456789012345LL, static_cast<long long int>(io));
}

TEST_IO(ReadUnsignedInt, 200, 30, "12345 -12345") {
  fastio_ReadUnsignedInt io;
  EXPECT_EQ(12345U, static_cast<unsigned int>(io));
  EXPECT_NE(12345U, static_cast<unsigned int>(io));
}

TEST_IO(ReadIntPipe, 200, 30, "1 12345 -1 -12345 123456789012345") {
  fastio_ReadIntPipe io;
  unsigned int a, b;
  int c, d;
  long long int e;
  io >> a >> b >> c >> d >> e;
  EXPECT_EQ(1U, a);
  EXPECT_EQ(12345U, b);
  EXPECT_EQ(-1, c);
  EXPECT_EQ(-12345, d);
  EXPECT_EQ(123456789012345LL, e);
}

TEST_IO(ReadIntLongBuffer, 6, 3, "1 2 3 4 5 6 7 8 9 10") {
  fastio_ReadIntLongBuffer io;
  int ans[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
  for (int i = 0; i < 10; i++)
    EXPECT_EQ(ans[i], static_cast<int>(io));
}

TEST_IO(ReadIntSpaces, 6, 3, "1 2   3    4\n5\n\n6\t7\t\n8\n  \n9 \n10") {
  fastio_ReadIntSpaces io;
  int ans[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
  for (int i = 0; i < 10; i++)
    EXPECT_EQ(ans[i], static_cast<int>(io));
}

TEST_IO(ReadWord, 200, 30, "ricbit ilafox\nvinil") {
  fastio_ReadWord io;
  EXPECT_EQ(string("ricbit"), io.word());
  EXPECT_EQ(string("ilafox"), io.word());
  EXPECT_EQ(string("vinil"), io.word());
}

TEST_IO(ReadLineUnix, 200, 30, "ricbit ilafox\nvinil") {
  fastio_ReadLineUnix io;
  EXPECT_EQ(string("ricbit ilafox"), io.line());
  EXPECT_EQ(string("vinil"), io.line());
}

TEST_IO(ReadLineMac, 200, 30, "ricbit ilafox\rvinil") {
  fastio_ReadLineMac io;
  EXPECT_EQ(string("ricbit ilafox"), io.line());
  EXPECT_EQ(string("vinil"), io.line());
}

TEST_IO(ReadLineWindows, 200, 30, "ricbit ilafox\r\nvinil") {
  fastio_ReadLineWindows io;
  EXPECT_EQ(string("ricbit ilafox"), io.line());
  EXPECT_EQ(string("vinil"), io.line());
}

TEST_IO(WriteInt, 200, 30, "") {
  {
    fastio_WriteInt io;
    io << 1U << " " << 12345U << " ";
    io << -1 << " " << -1599920001 << " ";
    io << 123456789012345LL;
  }
  EXPECT_EQ(string("1 12345 -1 -1599920001 123456789012345"),
            out_WriteInt::get());
}

TEST_IO(WriteString, 200, 30, "") {
  {
    fastio_WriteString io;
    io << "ricbit ";
    string ilafox("ilafox");
    io << ilafox << "\n";
  }
  EXPECT_EQ(string("ricbit ilafox\n"), out_WriteString::get());
}


