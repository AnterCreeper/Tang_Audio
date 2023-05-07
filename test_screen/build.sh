#!/bin/sh
arm-nuvoton-linux-musleabi-gcc -fno-strict-aliasing -fno-common -ffixed-r8 -msoft-float -Wformat -Wall -std=gnu99 -O3 test.c -lc -lgcc -lpthread -lrt
