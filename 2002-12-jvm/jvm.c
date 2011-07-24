#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <io.h>

unsigned char *buf;
int len,pos=0;
int *iscode;

unsigned int get_u4 (void) {
  unsigned int ret;

  if (len<4) {
    printf ("Error parsing file\n");
    exit (1);
  }
  ret=(buf[pos]<<24)+(buf[pos+1]<<16)+(buf[pos+2]<<8)+(buf[pos+3]<<0);
  pos+=4;
  len-=4;
  return ret;
}

unsigned int get_u2 (void) {
  unsigned int ret;

  if (len<2) {
    printf ("Error parsing file\n");
    exit (1);
  }
  ret=(buf[pos]<<8)+(buf[pos+1]<<0);
  pos+=2;
  len-=2;
  return ret;
}

unsigned int get_u1 (void) {
  unsigned int ret;

  if (len<1) {
    printf ("Error parsing file\n");
    exit (1);
  }
  ret=buf[pos];
  pos+=1;
  len-=1;
  return ret;
}

void get_constant (int number) {
  int type;
  int class_index,nametype_index;
  int string_index;
  int name_index,descriptor_index;
  int integer_value;
  int integer_value_low;
  int len,c,i;
  char *temp;

  type=get_u1();
  printf ("C[%d]: %2d, ",number,type);
  iscode[number]=0;
  switch (type) {
    case 7:
      printf ("CONSTANT_Class\n");
      name_index=get_u2();
      printf ("  Name index=%d\n",name_index);
      break;
    case 9:
      printf ("CONSTANT_Fieldref\n");
      class_index=get_u2();
      nametype_index=get_u2();
      printf ("  Class index=%d\n",class_index);
      printf ("  Name and Type index=%d\n",nametype_index);
      break;
    case 10:
      printf ("CONSTANT_Methodref\n");
      class_index=get_u2();
      nametype_index=get_u2();
      printf ("  Class index=%d\n",class_index);
      printf ("  Name and Type index=%d\n",nametype_index);
      break;
    case 11:
      printf ("CONSTANT_InterfaceMethodref\n");
      class_index=get_u2();
      nametype_index=get_u2();
      printf ("  Class index=%d\n",class_index);
      printf ("  Name and Type index=%d\n",nametype_index);
      break;
    case 8:
      printf ("CONSTANT_String\n");
      string_index=get_u2();
      printf ("  String index=%d\n",string_index);
      break;
    case 3:
      printf ("CONSTANT_Integer\n");
      integer_value=get_u4();
      printf ("  Integer value=%d\n",integer_value);
      break;
    case 4:
      printf ("CONSTANT_Float\n");
      break;
    case 5:
      printf ("CONSTANT_Long\n");
      integer_value=get_u4();
      integer_value_low=get_u4();
      printf ("  Integer value=0x%04X%04X\n",integer_value,integer_value_low);
      break;
    case 6:
      printf ("CONSTANT_Double\n");
      break;
    case 12:
      printf ("CONSTANT_NameAndType\n");
      name_index=get_u2();
      descriptor_index=get_u2();
      printf ("  Name index=%d\n",name_index);
      printf ("  Descriptor index=%d\n",descriptor_index);
      break;
    case 1:
      printf ("CONSTANT_Utf8\n");
      len=get_u2();
      temp=(char *) malloc (128+sizeof (len));
      printf ("  Length=%d\n",len);
      printf ("  Value=");
      for (i=0; i<len; i++) {
        c=get_u1();
        temp[i]=c;
        printf ("%c",c);
      }
      temp[i]=0;
      if (!strcmp (temp,"Code"))
        iscode[number]=1;
      free (temp);
      printf ("\n");
      break;
    default:
      printf ("Unknown, aborting.\n");
      exit (1);
  }
}

void get_attributes (int number);

void get_code (void) {
  int max_stack, max_locals,code_length;
  int exception_table_length;
  int attributes_count;
  int opcode,i=0;
  int arg1;

  printf ("Code:\n");
  max_stack=get_u2();
  max_locals=get_u2();
  code_length=get_u4();
  printf ("  Max Stack=%d\n",max_stack);
  printf ("  Max Locals=%d\n",max_locals);
  printf ("  Code Length=%d\n",code_length);
  do {
    opcode=get_u1();
    printf ("%04d: ",i);
    switch (opcode) {
      case 0x12:
        arg1=get_u1();
        printf ("ldc #%d\n",arg1);
        i+=1; code_length-=1;
        break;
      case 0x2A:
        printf ("aload_0\n");
        break;
      case 0xB1:
        printf ("return\n");
        break;
      case 0xB2:
        arg1=get_u2();
        printf ("getstatic #%d\n",arg1);
        i+=2; code_length-=2;
        break;
      case 0xB6:
        arg1=get_u2();
        printf ("invokevirtual #%d\n",arg1);
        i+=2; code_length-=2;
        break;
      case 0xB7:
        arg1=get_u2();
        printf ("invokespecial #%d\n",arg1);
        i+=2; code_length-=2;
        break;
      default:
        printf ("%02X\n",opcode);
        break;
    }
    i++; code_length--;
  } while (code_length);

  exception_table_length=get_u2();
  printf ("  Exception Table Length=%d\n",exception_table_length);
  if (exception_table_length) {
    printf ("Exception table not implemented yet\n");
    exit (1);
  }
    
  attributes_count=get_u2();
  printf ("  Attributes count=%d\n",attributes_count);
  for (i=0; i<attributes_count; i++)
    get_attributes (i);

}

void get_attributes (int number) {
  int name_index,len,i,c;
  int cpos;

  printf ("Attribute[%d]=\n",number);

  name_index=get_u2();
  printf ("  Name index=%d\n",name_index);

  len=get_u4();
  printf ("  Length=%d\n",len);
  if (!iscode) { 
    for (i=0; i<len; i++) 
      c=get_u1();
  } else {
    cpos=pos;
    get_code();
    if (pos-cpos!=len) {
      printf ("Internal error\n");
      exit (1);
    }
  }
}

void get_method (int number) {
  int access_flags;
  int name_index,descriptor_index;
  int attributes_count;
  int i;

  printf ("Method[%d]=\n",number);

  printf ("Access flags:\n");
  access_flags=get_u2();
  if (access_flags&0x0001)
    printf("  ACC_PUBLIC\n");
  if (access_flags&0x0002)
    printf("  ACC_PRIVATE\n");
  if (access_flags&0x0004)
    printf("  ACC_PROTECTED\n");
  if (access_flags&0x0008)
    printf("  ACC_STATIC\n");
  if (access_flags&0x0010)
    printf("  ACC_FINAL\n");
  if (access_flags&0x0020)
    printf("  ACC_SYNCHRONIZED\n");
  if (access_flags&0x0100)
    printf("  ACC_ABSTRACT\n");
  if (access_flags&0x0800)
    printf("  ACC_STRICT\n");
  if (!access_flags)
    printf("  NONE\n");

  name_index=get_u2();
  descriptor_index=get_u2();
  printf ("  Name index=%d\n",name_index);
  printf ("  Descriptor index=%d\n",descriptor_index);

  attributes_count=get_u2();
  printf ("  Attributes count=%d\n",attributes_count);
  for (i=0; i<attributes_count; i++)
    get_attributes (i);

}

int main (int argc, char **argv) {
  FILE *f;
  int i;

  int magic,minor_version,major_version;
  int constant_pool_count;
  int access_flags;
  int this_index,super_index;
  int interfaces_count;
  int fields_count;
  int methods_count;
  int attributes_count;

  f=fopen (argv[1],"rb");
  len=filelength (fileno (f));
  buf=(unsigned char *) malloc (len);
  fread (buf,1,len,f);
  fclose (f);

  printf ("Class File Debulhator Tabajara 1.0\n");
  printf ("by Ricardo Bittencourt\n\n");

  /* get magic number */

  magic=get_u4();
  if (magic!=0xCAFEBABE) {
    printf ("Not a valid class file\n");
    return 1;
  }
  printf ("Magic: %08X\n",magic);

  /* get version */

  minor_version=get_u2();
  major_version=get_u2();
  printf ("Version: %d.%d\n",major_version,minor_version);

  /* constant pool */

  constant_pool_count=get_u2();
  printf ("Constant pool count: %d\n",constant_pool_count);
  iscode=(int *) malloc (constant_pool_count*sizeof (int));

  for (i=1; i<=constant_pool_count-1; i++)
    get_constant (i);

  /* access flags */

  access_flags=get_u2();
  printf ("Access Flags:\n");
  if (access_flags&0x0001)
    printf("  ACC_PUBLIC\n");
  if (access_flags&0x0010)
    printf("  ACC_FINAL\n");
  if (access_flags&0x0020)
    printf("  ACC_SUPER\n");
  if (access_flags&0x0200)
    printf("  ACC_INTERFACE\n");
  if (access_flags&0x0400)
    printf("  ACC_ABSTRACT\n");
  if (!access_flags)
    printf("  NONE\n");

  /* this class */

  this_index=get_u2();
  printf ("This class index: %d\n",this_index);

  /* super class */

  super_index=get_u2();
  printf ("Super class index: %d\n",super_index);

  /* interfaces count */

  interfaces_count=get_u2();
  printf ("Interfaces count: %d\n",interfaces_count);
  if (interfaces_count!=0) {
    printf ("Interfaces not implemented yet\n");
    exit (1);
  }
    
  /* fields count */

  fields_count=get_u2();
  printf ("Fields count: %d\n",fields_count);
  if (fields_count!=0) {
    printf ("Fields not implemented yet\n");
    exit (1);
  }
    
  /* methods count */

  methods_count=get_u2();
  printf ("Methods count: %d\n",methods_count);
  for (i=1; i<=methods_count; i++)
    get_method (i);
    
  /* attributes count */

  attributes_count=get_u2();
  printf ("Global Attributes count: %d\n",attributes_count);
  for (i=0; i<attributes_count; i++)
    get_attributes (i);

  if (len) {
    printf ("Internal Error\n");
    exit (1);
  }

  return 0;
}

