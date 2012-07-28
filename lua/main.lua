--[[
	Taraf, a backing track generator.
	Author: Vlad Dumitru :: deveah@gmail.com

	Released under a Beerware-like licence. See LICENCE for details.
]]--

--[[
	TODO cleaner code, for example:
		the "let ring" lookahead can be calculated for each tick,
		not necessarily for every note

	TODO document new features: warnings; a number in the order table is a jump command
]]--

currentOrder = 1
maxPatternSize = 0

-- show warnings
warning = true

noteToMidi = {
	e  = 52,
	f  = 53,
	fs = 54,
	g  = 55,
	gs = 56,
	a  = 57,
	as = 58,
	b  = 47,
	c  = 48,
	cs = 49,
	d  = 50,
	ds = 51 }

function warn( s )
	if warning then
		print( "taraf warning: " .. s )
	end
end

function init()
	print( "Initializing Taraf..." )
	fluid.setDriver( defaultAudioDevice, defaultOutputFile );
	fluid.init()
	fluid.loadSFont( soundFontPath )

	maxPatternSize = getMaxPatternSize()


	if not style.name then
		warn( "Style has no name specified!" )
	end

	if not style.author then
		warn( "Style has no author specified!" )
	end

	if not style.defaultBPM then
		warn( "Style has no default BPM! BPM set temporarily to 100." )
		style.defaultBPM = 100
	end

	if not style.defaultSpeed then
		warn( "Style has no default speed! Speed temporarily set to 16." )
		style.defaultSpeed = 16
	end

	if not style.measure then
		warn( "Style has no measure specified! Assuming 4/4." )
		style.measure = 8
	end

	if not style.chordSweep then
		warn( "Style has no chord sweep speed specified! Assuming 0." )
		style.chordSweep = 0
	end

	local n = tonumber( args.note )
	if n == nil then
		if args.note == "?" or args.note == nil then
			math.randomseed( os.time( ) )
			deltaNote = math.floor( math.random( 47, 58 ) )
			io.write( "Random note chosen: " )
			for k, v in pairs( noteToMidi ) do
				if v == deltaNote then print( k ) end
			end
		else
			deltaNote = noteToMidi[ string.lower( args.note ) ]
		end
		if deltaNote == nil then
			warn( "Unable to get delta note. Assuming default." )
			deltaNote = defaultDeltaNote
		end
	elseif n > 0 and n < 128 then
		deltaNote = args.note
	else
		deltaNote = defaultDeltaNote
	end

	if args.bpm then
		realBPM = args.bpm
	else
		realBPM = style.defaultBPM
	end

	if args.tempo then
		realTempo = args.tempo
	else
		realTempo = style.defaultSpeed
	end

	-- set instruments
	
	if style.chordInstrument then
		ci = style.chordInstrument
	else
		warn( "Style has no chord instrument specified." )
		ci = 1 -- default MIDI 'Acoustic Grand Piano'
	end
	fluid.programChange( chordChannel, ci )

	if style.bassInstrument then
		bi = style.bassInstrument
	else
		warn( "Style has no bass instrument specified." )
		bi = 35 -- default MIDI 'Electric Bass (pick)'
	end
	fluid.programChange( bassChannel, bi )
	
	if not style.order then
		warn( "Style has no order table." )
		fluid.die()
	end
	
	print( "Playing " .. style.name .. " by " .. style.author ) 
end

function terminate()
	print( "Terminating Taraf..." )
	fluid.terminate()
end

function resizePattern( pattern, size )
	
	if not pattern then return nil end

	local q = size / #pattern
	local newpattern = {}

	for i = 1, #pattern do
		newpattern[q*(i-1)+1] = pattern[i]
		for j = 1, q-1 do
			newpattern[q*(i-1)+j+1] = "let ring"
		end
	end

	return newpattern
end

function getMaxPatternSize()
	local mb, mc, md = 0, 0, 0
	
	for i = 1, #style.chords do
		if #style.chords[i] > mc then
			mc = #style.chords[i]
		end
	end

	for i = 1, #style.bass do
		if #style.bass[i] > mb then
			mb = #style.bass[i]
		end
	end

	for i = 1, #style.drums do
		if #style.drums[i] > md then
			md = #style.drums[i]
		end
	end

	return math.max( mb, mc, md )
end

function debugPattern( pattern )
	for i, v in ipairs( pattern ) do
		print( ">>", i, v )
	end
end

function pattern()
	local sweep_delta = style.chordSweep

	local tickLength = 60000 / realBPM
	local spd = realTempo / style.measure



	if not headerPlayed then
		local t = style.measure / 2
		tickLength = tickLength * 2
		for i = 1, t do
			fluid.noteOn( drumChannel, 56, 100, ( tickLength / spd ) * i )
			fluid.noteOff( drumChannel, 56, ( tickLength / spd ) * ( i + 1 ))
		end
		headerPlayed = true
		fluid.scheduleCallback( ( t / spd ) * tickLength + ( 1/spd ) * tickLength / 2 )
		tickLength = tickLength / 2
		return nil
	end

	drumpattern = resizePattern( style.drums[style.order[currentOrder][1]], maxPatternSize )
	if drumpattern then
		for i = 1, #drumpattern do
			if drumpattern[i] ~= "let ring" and drumpattern[i] ~= "pause" then
				fluid.noteOn( drumChannel, drumpattern[i], style.drumsVol, ( tickLength / spd ) * i )
				fluid.noteOff( drumChannel, drumpattern[i], ( tickLength / spd ) * ( i + 1 ) )
			end
		end
	end

	chordpattern = resizePattern( style.chords[style.order[currentOrder][2]], maxPatternSize )
	local note = 0
	local ringlength = 1

	if chordpattern then
		for i = 1, #chordpattern do
			if chordpattern[i] ~= "let ring" and chordpattern[i] ~= "pause" then
				for j = 1, #chordpattern[i][2] do
					note = deltaNote + chordpattern[i][1] + chordpattern[i][2][j]
					fluid.noteOn( chordChannel, note, style.chordsVol, ( tickLength / spd ) * i + sweep_delta*j )
					ringlength = 1
					while chordpattern[i+ringlength] == "let ring" do
						ringlength = ringlength + 1
					end
					fluid.noteOff( chordChannel, note, ( tickLength / spd ) * ( i + ringlength ))
				end
			end
		end
	end

	basspattern = resizePattern( style.bass[style.order[currentOrder][3]], maxPatternSize )
	local note = 0
	local ringlength = 1

	if basspattern then
		for i = 1, #basspattern do
			if basspattern[i] ~= "let ring" then
				note = deltaNote + basspattern[i] - 24
				fluid.noteOn( bassChannel, note, style.bassVol, ( tickLength / spd ) * i )
				while basspattern[i+ringlength] == "let ring" do
					ringlength = ringlength + 1
				end
				fluid.noteOff( bassChannel, note, ( tickLength / spd ) * ( i + ringlength ))
			end
		end
	end

	if style.order[currentOrder+1] == "repeat" then
		currentOrder = 1
	elseif type( style.order[currentOrder+1] ) == "number" then
		currentOrder = style.order[currentOrder+1]
	else
		currentOrder = currentOrder + 1
	end
	
	fluid.scheduleCallback( ( maxPatternSize / spd ) * tickLength )
end	
