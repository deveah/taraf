
style = {}
style.name = "Easy Rock"
style.author = "default package"

style.defaultSpeed = 10
style.defaultBPM = 120
style.measure = 8

style.chordInstrument = 30
style.bassInstrument = 35

style.chords = {}
style.chordsVol = 60
style.chords[1] = {
	{ 0, fifth },
	"let ring",
	"let ring",
	{ -2, fifth }
}

style.chords[2] = {
	{ -2, min },
	"let ring",
	"let ring",
	{ -1, fifth }
}

style.chords[3] = {
	{ -2, min }
}

style.drums = {}
style.drumsVol = 120
style.drums[1] = {
	bd, ch, sd, ch
}

style.drums[2] = {
	cr
}

style.bass = {}
style.bassVol = 120
style.bass[1] = {
	0, 0, 0, -2
}

style.bass[2] = {
	-2, -2, -2, -1
}

style.bass[3] = {
	-2
}

style.order = {
--		drums	chords	bass
	{	1,		1,		1	},
	{	1,		1,		1	},
	{	1,		1,		1	},
	{	1,		2,		2	},
	{	1,		1,		1	},
	{	1,		1,		1	},
	{	1,		1,		1	},
	{	3,		3,		3	},
	"repeat"
}
