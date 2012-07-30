#!/bin/sh

gcc src/taraf.c -o taraf -I/usr/include/lua5.1 -llua5.1 -lpthread -lfluidsynth -Wall -Wextra -g2
