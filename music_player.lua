local lib = {volume = 1,playing = false}

local bby = {}

local song = {
-- {interval = 20,{"pling",-2,1},{"wait",4},{"snare",10,1},{"wait",10},{"sanre",24,1},{"wait",4},{"snare",5,2}},
-- {interval = 80,{"harp",13,.5},{"wait",10},{"harp",5},{"wait",8},{"harp",15},{"wait",4},{"harp",18},{"wait",3},{"harp",10}},
-- {interval = 40,{"chime",0},{"wait",8},{"chime",4},{"wait",8},{"chime",8},{"wait",8},{"chime",12}}
-- {interval = 5, {"guitar",20,10}}
-- {{"bell",-24},{"wait",10}},
{{"harp",13},{"wait",3},{"harp",5},{"wait",1},{"harp",13},{"wait",1},{"harp",15},{"harp",3},{"wait",6},{"harp",18},{"wait",5},{"harp",10},{"wait",4},{"harp",24},{"harp",12},{"wait",8},{"harp",15},{"wait",1},{"harp",12},{"wait",1},{"harp",12},{"wait",1},{"harp",25},{"harp",13},{"wait",5},{"harp",10},{"wait",6},{"harp",20},{"harp",8},{"wait",8}}
}
local songDaWay = {}

local function playNote( noteBlockUses, instrument,volume)
	local pos = client:getCameraPos():add(client:getCameraDir())
   local instrument = instrument or 'harp'
   local pitch = 2 ^ ((noteBlockUses - 12) / 12)
   sounds:playSound('minecraft:block.note_block.' .. instrument, pos, volume or lib.volume or 1, pitch)
end

function countNumInd(t)
	local cnt = 0
	for i,_ in pairs(t) do
		cnt = type(i) == "number" and cnt + 1 or cnt
	end
	return cnt
end

local function playStep(ind,meta)
	local block = song[ind]
	local step = block[meta.step]
	if not step then return end
	if step[1] == "wait" then
		meta.wait = step[2]
	else
		playNote(step[2],step[1],step[3] or block.vol)
		meta.step = meta.step + 1
		playStep(ind,meta)
	end
end

function events.tick()
 if not lib.playing then return end
	for i,v in ipairs(song) do
		local songMeta = songDaWay[i]
		local numInd = countNumInd(v)
		if numInd == 1 and (v.interval == 1 or v.interval == nil) then
			host:setActionbar(v[1][2].." "..v[1][1])
			playNote(v[1][2],v[1][1])
		end

		if songMeta then
		local step = v[songMeta.step]
			if songMeta.step > numInd then
				songDaWay[i] = nil

				return
			end
			if  songMeta.wait and  songMeta.wait >0 then
				songMeta.wait = songMeta.wait - 1
			elseif (step[1] == "wait" and songMeta.wait == 0) then
				songMeta.step = songMeta.step + 1
				playStep(i,songMeta)
				songMeta.wait = nil
			elseif  step[1] == "wait" then
				playStep(i,songMeta)
			elseif step[1] ~= "wait" then
				playStep(i,songMeta)
			end

		elseif not songMeta and (not v.interval or world.getTime()%v.interval == 0 )then
			songDaWay[i] = {step = 1,steps = numInd}
		else
		end

	end
end

return lib
