#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

int main(int argc, char** argv){

	int count = 0;
	int size = 0; //in 512 bytes
	int pos[128];

	memset(pos, 0, 512);

	if (argc != 3) {
		printf("missing args!\n");
		exit(-1);
	}
	FILE* fd_list = fopen(argv[1], "r");
	if (!fd_list) {
		printf("cannot open list file.");
		exit(-1);
	}
	FILE* fd_dst = fopen(argv[2], "wb");
	if (!fd_dst) {
		printf("cannot write target file.");
		exit(-1);
	}
	char buf[512];
	memset(buf, 0, 512);

	fwrite(buf, sizeof(buf), 1, fd_dst);

	char str[128];
	while(fgets(str, 128, fd_list)) {
		str[strcspn(str, "\n")] = 0;
		FILE* fd_src = fopen(str, "rb");
		printf("opening file %s\n", str);
		if (!fd_src) {
			printf("Error opening file: %s\n", strerror(errno));
			exit(-1);
		}
		int tag = 0;
		do {
			do tag = fgetc(fd_src); while (tag != 'd');
			tag <<= 24;
			fread(&tag, 1, 3, fd_src);
		} while (tag != 0x64617461);

		fread(&tag, 4, 1, fd_src);
		tag -= 4;
		int i = tag / 512;
		int j = tag % 512;

		pos[count] = size + 1;
		count++;
		size += i + (j != 0);

		for (int c = 0; c < i; c++) {
			fread(buf, 512, 1, fd_src);
			fwrite(buf, 512, 1, fd_dst);
		}

		if (j) {
			memset(buf, 0, 512);
			fread(buf, 512, 1, fd_src);
			fwrite(buf, 512, 1, fd_dst);
		}

		fclose(fd_src);
	}

	fseek(fd_dst, 0, SEEK_SET);
	int i = 128 / count;
	int j = 128 % count;
	for (int c = 0; c < i; c++) fwrite(pos, 4, count, fd_dst);
	fwrite(pos, 4, j, fd_dst);

	fclose(fd_dst);
	fclose(fd_list);
	return 0;
}
