
style = {}
style.name = "Basic Example"
style.author = "default package"

style.defaultSpeed = 32
style.defaultBPM = 140
style.measure = 8

style.chordInstrument = 20
style.bassInstrument = 34

style.chords = {}
style.chordsVol = 60
style.chords[1] = {
	{  0,	min	},
	"let ring",
	{ -2,	min },
	{  1,	min } }

style.drums = {}
style.drumsVol = 120
style.drums[1] = {
	bd, ch, xx, ch,
	sd, ch, xx, ch,
	bd, ch, xx, ch,
	sd, ch, mt, lt }

style.bass = {}
style.bassVol = 120
style.bass[1] = {
	0, 0, 0, 0,
	-2, -2, 1, 1 }

style.order = {
--		drums	chords	bass
	{	1,		nil,	nil		},
	{	1,		1,		1 		},
	2
}
