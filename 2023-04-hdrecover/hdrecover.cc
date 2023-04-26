#include <csetjmp>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <iostream>
#include <cstdio>
#include <jpeglib.h>

using namespace std;

class HDImage {
 public:
  HDImage(const char *name) {
    auto fd = open(name, O_RDONLY | O_LARGEFILE);
    struct stat sb;
    fstat(fd, &sb);
    size = sb.st_size;
    addr = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
  }
  ~HDImage() {
    munmap(addr, size);
  }
  size_t get_size() const {
    return size;
  }
  operator unsigned char*() const {
    return static_cast<unsigned char *>(addr);
  }
 private:
  size_t size;
  void *addr;
};

struct error_handler {
  struct jpeg_error_mgr error_mgr;
  jmp_buf setjmp_buffer;
};

[[noreturn]] void set_error(j_common_ptr cinfo) {
  auto handler = reinterpret_cast<error_handler*>(cinfo->err);
  longjmp(handler->setjmp_buffer, 1);
}

ptrdiff_t is_jpeg_stream(unsigned char* data, size_t size) {
  struct jpeg_decompress_struct cinfo;
  error_handler handler;
  cinfo.err = jpeg_std_error(&handler.error_mgr);
  handler.error_mgr.error_exit = set_error;
  handler.error_mgr.output_message = set_error;
  if (setjmp(handler.setjmp_buffer)) {
    jpeg_destroy_decompress(&cinfo);
    return 0;
  }
  jpeg_create_decompress(&cinfo);
  jpeg_mem_src(&cinfo, static_cast<unsigned char*>(data), size);
  jpeg_read_header(&cinfo, TRUE);
  jpeg_start_decompress(&cinfo);
  auto row_stride = cinfo.output_width * cinfo.output_components;
  auto jpeg_alloc = *cinfo.mem->alloc_sarray;
  auto common_ptr = reinterpret_cast<j_common_ptr>(&cinfo);
  auto buffer = jpeg_alloc(common_ptr, JPOOL_IMAGE, row_stride, 1);
  while (cinfo.output_scanline < cinfo.output_height) {
    jpeg_read_scanlines(&cinfo, buffer, 1);
  }
  ptrdiff_t output_size = cinfo.src->next_input_byte - data;
  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  return output_size;
}

void log(size_t i, int nimages) {
  if (i % 100'000'000 == 0) {
    cerr << i / 1024 / 1024 << " " << nimages << char(0xd);
  }
}

void save_image(unsigned char* addr, size_t size, int nimages) {
  char namebuf[100];
  sprintf(namebuf, "images/file%d.jpg", nimages);
  auto f = fopen(namebuf, "wb");
  fwrite(addr, 1, size, f);
  fclose(f);
}

int main(int argv, char **argc) {
  if (argv < 2) {
    cout << "Usage: hdrecover hddimage\n";
    return 0;
  }
  HDImage image(argc[1]);
  int nimages = 0;
  constexpr int buffer_size = 20 * 1024 * 1024;
  for (size_t i = 0; i < image.get_size(); i++) {
    log(i, nimages);
    if (image[i] == 0xFF && image[i + 1] == 0xD8 && image[i + 2] == 0xFF) {
      if (int size = is_jpeg_stream(image + i, buffer_size); size) {
        save_image(image + i, size, nimages++);
      }
    }
  }

  return 1;
}
