#!/bin/sh

gcc src/taraf.c -o taraf -llua -lpthread -lfluidsynth -Wall -Wextra -g2
