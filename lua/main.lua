--[[
	Taraf, a backing track generator.
	Author: Vlad Dumitru :: deveah@gmail.com

	Released under a Beerware-like licence. See LICENCE for details.
]]--

--[[
	TODO cleaner code, for example:
		the "let ring" lookahead can be calculated for each tick,
		not necessarily for every note

	TODO resize patterns based on largest pattern!
]]--

currentOrder = 1
maxPatternSize = 0

function init()
	print( "Initializing Taraf..." )
	fluid.init()
	fluid.loadSFont( "./default.sf2" )

	maxPatternSize = getMaxPatternSize()
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
	-- find max in chords
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
	-- TODO: style-based default note and sweep duration!
	local delta_note = 55
	local sweep_delta = 0

	local tickLength = 60000 / style.defaultBPM
	local spd = style.defaultSpeed / style.measure

	if style.order[currentOrder+1] == "repeat" then
		currentOrder = 1
	else
		currentOrder = currentOrder + 1
	end

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

	-- TODO: change instruments from within the style
	fluid.programChange( chordChannel, 90 )
	fluid.programChange( bassChannel, 35 )


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
					note = delta_note + chordpattern[i][1] + chordpattern[i][2][j]
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
				note = delta_note + basspattern[i] - 24
				fluid.noteOn( bassChannel, note, style.bassVol, ( tickLength / spd ) * i )
				while basspattern[i+ringlength] == "let ring" do
					ringlength = ringlength + 1
				end
				fluid.noteOff( bassChannel, note, ( tickLength / spd ) * ( i + ringlength ))
			end
		end
	end

	fluid.scheduleCallback( ( maxPatternSize / spd ) * tickLength )
end	
