#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <sys/time.h>
#include <signal.h>
#include <semaphore.h>
#include <sys/ioctl.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <errno.h>

#include "spidev.h"

#define MAX_TRANSFER_SIZE 65536

struct spidev{
	int fd;
        uint8_t bits;
        uint32_t mode;
        uint32_t speed;
	struct spi_ioc_transfer buf;
};

void spi_init(char* devname, struct spidev* dev) {
	dev->fd = open(devname, O_RDWR);
	if (dev->fd < 0) {
		printf("FIXME! can't open device!\n");
		exit(1);
	}

	/*
	 * spi mode
	 */
	if (ioctl(dev->fd, SPI_IOC_WR_MODE, &dev->mode) == -1) {
		printf("can't set spi write mode!\n");
		exit(-1);
	}
	if (ioctl(dev->fd, SPI_IOC_RD_MODE, &dev->mode) == -1) {
		printf("can't set spi read mode!\n");
		exit(-1);
	}
	/*
	 * bits per word
	 */
	if (ioctl(dev->fd, SPI_IOC_WR_BITS_PER_WORD, &dev->bits) == -1) {
		printf("can't set write bits per word!\n");
		exit(-1);
	}
	if (ioctl(dev->fd, SPI_IOC_RD_BITS_PER_WORD, &dev->bits) == -1) {
		printf("can't set read bits per word!\n");
		exit(-1);
	}
	/*
	 * max speed hz
	 */
	if (ioctl(dev->fd, SPI_IOC_WR_MAX_SPEED_HZ, &dev->speed) == -1) {
		printf("can't set write max speed!\n");
		exit(-1);
	}
	if (ioctl(dev->fd, SPI_IOC_RD_MAX_SPEED_HZ, &dev->speed) == -1) {
		printf("can't set read max speed!\n");
		exit(-1);
	}

	printf("spi device set successfully!\n");
	printf("spi mode:%x\n", dev->mode);
	printf("bits per word:%d\n", dev->bits);
	printf("max speed: %lf MHz\n", (float)dev->speed / 1000000);

	printf("buffer prepared!\n");
        dev->buf.delay_usecs = 0;
        dev->buf.speed_hz = dev->speed;
        dev->buf.bits_per_word = dev->bits;
	dev->buf.tx_nbits = 1;
	dev->buf.rx_buf = (unsigned int)NULL;
	return;
}

struct {
	FILE* fd;
	struct spidev dev;
	sem_t sem_eof;
} tx_worker_data;

#define unlikely(x) __builtin_expect(!!(x), 0)
#define min(x, y) unlikely((x) < (y)) ? (x) : (y)

//transfer only
void spi_transfer(struct spidev* dev, unsigned char* buffer, int32_t length) {
	if (buffer == NULL) {
		printf("FIXME! empty buffer!\n");
		exit(1);
	}
	int processed = 0;
	while (length - processed > 0) {
		int size = min(length - processed, MAX_TRANSFER_SIZE);
		dev->buf.len = size;
		dev->buf.tx_buf = (unsigned int)&buffer[processed];
		dev->buf.rx_buf = (unsigned int)NULL;
		if (ioctl(dev->fd, SPI_IOC_MESSAGE(1), &dev->buf) < 1) {
			printf("FIXME! cannot send spi message!\n");
			printf("errno:%d %s\n", errno, strerror(errno));
			exit(1);
		}
		processed = processed + size;
	}
	return;
}

#define PAGE_SIZE 1024

void read_data(unsigned char* buf, FILE* fd) {
	for (int k = 0; k < 8; k++)
	for (int i = 0; i < 8; i++) {
		for (int j = 0; j < 128; j++) {
			unsigned char data;
			fread(&data, 1, 1, fd);
			buf[j + 128 * k] = buf[j + 128 * k] | (((data > 127) ? 1 : 0) << i);
		}
	}
	return;
}

int count = 0;

void tx_worker() {
	if (!feof(tx_worker_data.fd)) {
		unsigned char* buffer;
		buffer = malloc(PAGE_SIZE);
		memset(buffer, 0, PAGE_SIZE);
		read_data(buffer, tx_worker_data.fd);
		printf("block%d:\n", count);
		spi_transfer(&tx_worker_data.dev, buffer, PAGE_SIZE);
		char filename[256];
		sprintf(filename, "output%d.bin", count++);
		FILE* test_fd = fopen(filename, "wb");
		fwrite(buffer, 1, PAGE_SIZE, test_fd);
		fclose(test_fd);
		free(buffer);
	} else {
		sem_post(&tx_worker_data.sem_eof);
	}
        return;
}

int main(int argc, char* argv[]){
	if (argc == 1 || argv[1][0] == '\0') {
		printf("FIXME! no file args.\n");
		exit(1);
	}
	if (argc == 2 || argv[2][0] == '\0') {
		printf("FIXME! no dev args.\n");
		exit(1);
	}
	int spi_speed;
	if (argc == 3 || argv[3][0] == '\0') {
		spi_speed = 1000000;
		printf("using default speed: 1MHz\n");
	} else {
		spi_speed = atoi(argv[3]);
		printf("using user specifice speed: %lfMHz\n", (float)spi_speed / 1000000);
	}

	FILE* fd = fopen(argv[1], "rb");
	if (fd == NULL) {
		printf("FIXME! error while opening file.\n");
		exit(1);
	}

	struct spidev dh;
	dh.bits = 8;
	dh.mode = 0;
	dh.speed = spi_speed;
	spi_init(argv[2], &dh);

	FILE* fd_cfg;
	fd_cfg = fopen("/sys/class/gpio/export", "w");
	if (fd_cfg == NULL) {
		printf("FIXME! error while setting gpio export.\n");
		exit(1);
	}
	fprintf(fd_cfg, "%d", 67); //2 * 0x20 + 3
	fclose(fd_cfg);

	fd_cfg = fopen("/sys/class/gpio/gpio67/direction", "w");
	if (fd_cfg == NULL) {
		printf("FIXME! error while setting gpio direction.\n");
		exit(1);
	}
	fprintf(fd_cfg, "out");
	fclose(fd_cfg);

	fd_cfg = fopen("/sys/class/gpio/gpio67/value", "w");
	if (fd_cfg == NULL) {
		printf("FIXME! error while setting gpio value.\n");
		exit(1);
	}
	fprintf(fd_cfg, "0");
	fclose(fd_cfg);

	unsigned char settings[] =
		{0x8D, 0x10, //no charge pump
		 0xAD, 0x50, //internal iref
		 0x20, 0x00, //COM Page H-mode
//		 0xDA, 0x00,
		 0xD9, 0xF1, //precharge period
		 0x40,
		 0x22, 0x00, 0x07,
		 0xAF, //enable display
		 0xA5};//full write test

	spi_transfer(&dh, settings, sizeof(settings));

	sleep(1);

	unsigned char settings1[] = {0xA4};
	spi_transfer(&dh, settings1, sizeof(settings1));

	sleep(1);

	fd_cfg = fopen("/sys/class/gpio/gpio67/value", "w");
	if (fd_cfg == NULL) {
		printf("FIXME! error while setting gpio value.\n");
		exit(1);
	}
	fprintf(fd_cfg, "1");
	fclose(fd_cfg);

	sleep(1);

	tx_worker_data.fd = fd;
	tx_worker_data.dev = dh;

        sem_init(&tx_worker_data.sem_eof, 0, 0);

	int clock_interval = 33333333; //30fps

        timer_t timer;
        struct sigevent evp;
        memset(&evp, 0, sizeof(evp));
        evp.sigev_notify = SIGEV_THREAD;
        evp.sigev_notify_function = &tx_worker;
        evp.sigev_value.sival_ptr = &timer;
        if (timer_create(CLOCK_MONOTONIC, &evp, &timer)) {
                printf("set tx worker failed.\n");
                exit(1);
        }

        struct itimerspec ts;
        ts.it_interval.tv_sec = 0;
        ts.it_interval.tv_nsec = clock_interval;
        ts.it_value.tv_sec = 0;
        ts.it_value.tv_nsec = clock_interval;
        if (timer_settime(timer, 0, &ts, NULL)) {
                printf("start timer failed.\n");
                exit(1);
        }

        sem_wait(&tx_worker_data.sem_eof);
        sem_destroy(&tx_worker_data.sem_eof);

	fclose(tx_worker_data.fd);
	close(dh.fd);
	return 0;
}
