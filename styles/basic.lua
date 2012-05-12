
style = {}
style.name = "Basic Example"
style.author = "default package"

style.defaultSpeed = 32
style.defaultBPM = 140
-- TODO measure is ( how many eights fit in one measure )
style.measure = 8

style.chords = {}
style.chordsVol = 100
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
style.bassVol = 100
style.bass[1] = {
	0, 0, 0, 0,
	-2, -2, 11, 13 }

style.order = {
--		chords	bass	drums
	{	1,		1,		1 		},
	"repeat"
}
