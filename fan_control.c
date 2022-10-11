#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <fcntl.h>

#include <unistd.h>

#define EC_FAN_OFFSET 0x93

void set_speed(int fd, uint8_t speed) {
  uint8_t ec[2] = {0x14, speed};
  pwrite(fd, ec, sizeof(ec), EC_FAN_OFFSET);
}

void set_auto(int fd) {
  uint8_t ec[1] = {0x04};
  pwrite(fd, ec, sizeof(ec), EC_FAN_OFFSET);
}

void print_fan_info(int fd) {
  uint8_t ec[3];
  pread(fd, ec, 3, EC_FAN_OFFSET);

  printf("         fan mode : %x\n", ec[0]);
  printf("Selected fan speed: %3d (0x%2x)\n", ec[1], ec[1]);
  printf("Actual   fan speed: %3d (0x%2x)\n", ec[2], ec[2]);
}

void print_usage(char** argv) {
  fprintf(stderr, "USAGE: %s [-a] [-p] [-s speed]\n", argv[0]);
}

int main(int argc, char** argv) {
  if (argc <= 1) {
    print_usage(argv);
    return EXIT_FAILURE;
  }
  
  int fd = open("/sys/kernel/debug/ec/ec0/io", O_RDWR);
  if (fd < 0) {
    perror("open ec0/io error");
    return EXIT_FAILURE;
  }

  // modprobe ec_sys write_support=1

  int opt;
  int speed;

  while ((opt = getopt(argc, argv, "pas:")) != -1) {
    switch (opt) {
    case 'p':
      print_fan_info(fd);
      break;
    case 'a':
      set_auto(fd);
      printf("Set to auto\n");
      break;
    case 's':
      speed = atoi(optarg);
      if (speed > 255) speed = 255;
      set_speed(fd, (uint8_t) speed);
      printf("Set to speed %d (0x%x)\n", speed, speed);
      break;
    default:
      print_usage(argv);
      close(fd);
      return EXIT_FAILURE;
    }
  }

  close(fd);
  return EXIT_SUCCESS;
}
