#!/bin/sh
#merge mai bine cu rugăciuni

sudo apt-get install git build-essential liblua5.1-dev libfluidsynth-dev
git clone https://github.com/deveah/taraf.git
cd taraf/
./iemake.sh
