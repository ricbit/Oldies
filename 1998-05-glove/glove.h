#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  int f1,f2,f3,f4,f5;
  int raw,pitch;
} glove_data;

void set_com_base (int port);
int glove_init (void);
void get_glove_data (glove_data *data);

#ifdef __cplusplus
}
#endif

