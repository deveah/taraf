
-- taraf - global data

-- path to the soundfont used to render the sound
soundFontPath = "default.sf2"

-- defaults
-- audio device; can be: jack, alsa, oss, pulseaudio, coreaudio, dsound, portaudio, sndman, dart or file.
defaultAudioDevice = "alsa"
-- output filename, in case the audio device is "file".
defaultOutputFile = "tarafout.wav"
-- default delta note, in case it is not specified:
defaultDeltaNote = 60 -- middle C

-- channel numbers
chordChannel = 1
bassChannel = 2
drumChannel = 9

-- chord listing
maj 	= {	0,	4,	7		}
min 	= {	0,	3,	7		}
fifth 	= {	0,	7,	12		}
dom7th	= {	0,	4,	7,	10	}
maj7th	= {	0,	4,	7,	11	}
min7th	= {	0,	3,	7,	10	}

-- drum instrument specification
-- pause
xx = "pause"
-- bass drum
bd = 36
-- hats: closed/open/crash
ch = 44
oh = 46
cr = 49
-- snare drum
sd = 38
-- toms: low/mid/high
lt = 43
mt = 45
ht = 47

