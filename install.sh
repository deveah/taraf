#!/bin/sh
#merge mai bine cu rugăciuni

sudo apt-get install git build-essentials liblua5.2-dev libfluidsynth-dev
git clone https://github.com/deveah/taraf.git
cd taraf/
./make.sh
