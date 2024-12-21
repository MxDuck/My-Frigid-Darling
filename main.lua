---Durrh, umm, sorry for no comments, I guess. you're free to clean my code up.
if not host:isHost() then return end

local ID = "MY_COLD_DARLING"
local id = ID:lower()
config:name(ID)

local GNUI = require("GNUI.main")
local Button = require("GNUI.element.button")
local Slider = require("GNUI.element.slider")
local GNUITheme = require("GNUI.theme.gntheme")
local newBox = GNUI.newBox
local playSound = GNUI.playSound
local music = require("music_player")
music.volume = .6
music.playing = true
GNUITheme.volume = .3
local ABS, MIN, MAX, CLAMP, SIGN, GETWINDOWSIZE,GETGUISCALE, TINSERT, TREMOVE, TUNPACK =
math.abs, math.min, math.max, math.clamp, math.sign, client.getWindowSize, client.getGuiScale, table.insert,table.remove,table.unpack
local function tableCopy(t) return {TUNPACK(t)} end
--Here you can see a deepcopy function I didn't make.
local function deepCopyTable(t)
	local og_type = type(t)
	local copy
	if og_type == "table" then
		copy = {}
		for k,v in pairs(t) do
			copy[k] = deepCopyTable(v)
			setmetatable(copy,getmetatable(t))
		end
	else
		copy = t
	end
	return copy
end

local menu_state = false
local game = {playing = true,started = false}
local spritemap = textures["assets.sprites"]
local MLI_body = GNUI.newNineslice(textures["assets.MLI_poses"])
local MLI_face = GNUI.newNineslice(textures["assets.MLI_faces"])
local poses = {neutral = 1, shrug = 2,arms_down = 3,chin_grab = 4,face_grab = 5,regal_hold = 6,mxduck = 7}
local faces = {neutral = 1,shocked = 2,angry = 3,surprised = 4,curious = 5,curious_smirk = 6,neutral_look = 7,laugh = 8,smirk = 9,smirk_smitten = 10, shocked_smitten = 11, laugh_smitten = 12,surprised_look_smitten = 13,neutral_look_smitten = 14,wide_smitten = 15,neutral_smitten = 16,angry_smitten = 17,surprised_smitten = 18,curious_smitten = 19,testing = 20,none = "none"}
local backdrops = {"park_bench","cat_cafe_out","cat_cafe_in","soup_way","pool","vending_machines","arcade_machines","observatory","theater"}
for i=1,#backdrops do
	local s = backdrops[i]
	backdrops[s] = textures["assets."..s]
end

local defTxtr = textures["1x1white"] or textures:newTexture("1x1white",1,1):setPixel(0,0,vec(1,1,1,.8))
local vecuno = vec(1,1)
local settings = config:load("SETTINGS") or {volume_voice = 1,volume_music = .6,volume_fx = .3}
local testTxt = "Omae wae shinderu, amirite, lads, or amirite, lads? You know, they used to say that back in the great war of gergeny, where gerg almost took over the entire town of flunkrle. But then Cone swooped in and saved us all, bless Cone. May Cone be all and all be Cone."
local currentNode = "start"

local chars = {
	Player = {name  = "Neko",revealed = true,events = {}},
	MLI = {name = "Milly",status = "fine",revealed = false,events = {}}
}
local gameState = config:load("GAME_STATE") or {
	path = {{node = "start", musicPlaying = true, chars = deepCopyTable(chars)
	}},
	currStep = 1,
	musicPlaying = true,
	chars = deepCopyTable(chars)
}
chars = nil
local movement = {
	"key.back",
	"key.forward",
	"key.left",
	"key.right"
}
local continues = {
	space = keybinds:newKeybind("next","key.keyboard.space"),
	right = keybinds:newKeybind("next","key.keyboard.right"),
	down = keybinds:newKeybind("next","key.keyboard.down")
}
local backs = {
 right = keybinds:newKeybind("back","key.keyboard.left"),
 down = keybinds:newKeybind("back","key.keyboard.up")
}
local rightclick = keybinds:newKeybind("menu","key.mouse.right")
-- local chars,charPlayer,charMLI = gameState.chars,gameState.chars.Player,gameState.chars.MLI

local function applySettings(ms,vc,fx)
	music.volume = settings.volume_music
	GNUITheme.volume = settings.volume_fx
end
local function saveSettings()
	config:save("SETTINGS",settings)
end
applySettings()
local function saveGameState(i)
	local id = "GAME_STATE"..i or ""
	local scrnsht = host:screenshot(id):save()
	config:save(id,gameState)
	config:save(id.."_sc",scrnsht)
end
local function loadGameState(i)
	local id = "GAME_STATE"..i or ""
	local gmst = config:load(id)

	gameState = gmst or gameState
	return gmst
end
local function retrieveSaveTexture(i)
	local id = "GAME_STATE"..i or ""
	local txtr = config:load(id.."_sc")
	if txtr then
		return textures:read(id,txtr)
	else
		return defTxtr
	end
end

local function tallyEvents()
	local event =  gameState.chars.Player.events
	local joke,flirt,play,swim,pet =  event.scatman, event.flirtWithMLI,event.playedArcade,event.swamInPool,event.petCats
	local evnts = {joke and "making jokes together",flirt and "flirting with each other",play and "playing games together",swim and "swimming together",pet and "petting cats together"}
	local t = {}
	local msg,amount = "Despite ${MLI}'s cold exterior, you both spend your time as "..(gameState.chars.MLI.relationship or "friends").." ", #evnts
	for i,v in pairs(evnts) do
		if v~=nil then
			TINSERT(t,v)
		end
	end
	amount = #t
	if amount == 0 then
		msg = msg.."doing absolutely nothing."
	else
		for i,v in ipairs(t) do
			if amount == 1 then
				msg = msg..v.."."
			elseif amount == 2 then
				if i == 1 then
					msg = msg..v.." and "
				else
					msg = msg..v.."."
				end
			elseif i == amount then
				msg = msg..", and "..v.."."
			elseif i == 1 then
				msg = msg..v
			else
				msg = msg..", "..v
			end
		end
	end
	return msg
end


local story
story = {
	EMPTY_NODE = {
		text = {text = ""},
		name = "",
		options = {
			{choice = "", goTo = ""}
		},
		sprite = {char = "MLI",}
	},
	MILLY_NODE = {
		text = {text = "My name is Millias Aloof. You may know me as Milly."},
		name = "Milly(Millias Aloof)",
		options = {
			{choice = "Who are you?", goTo = "MILLY_NODE"}
		},
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	start = {
		backdrop = "park_bench",
		text = {text = "You've recently joined the Figura community, and have been wandering the plaza, when you fell into some mud! Someone nearby witnessed your predicament."},
		name = "Story",
		goTo = "introduce_MLI"
	},
	introduce_MLI = {
		backdrop = "park_bench",
		text = {text = "Hmph. Someone's quite clumsy."},
		name = {char = "MLI"},
		sprite = {char = "MLI",base = "neutral",face = "neutral"},
		options = {
			{choice = "Flirt with them", goTo = "intr_flirt"},
			{choice = "Retaliate", goTo = "intr_retaliate"},
			{choice = "Gush over them", goTo = "intr_gush1"},
			{choice = "Greet them", goTo = "intr_converse"}
		},
		script = function() playSound("MLI_HMPH",1,settings.volume_voice) end
	},
	intr_flirt = {
		backdrop = "park_bench",
		text = {text = "Did that fall kill me? 'Cuz I think I see an angel."},
		name ="You",
		goTo = "in_flirt1",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
		script = function() gameState.chars.MLI.status = "bashful" gameState.chars.Player.events.flirtWithMLI = true  end
	},
	in_flirt1 = {
		backdrop = "park_bench",
		text = {text = "... Well..."},
		name = {char = "MLI"},
		goTo = "in_flirt2",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"}
	},
	in_flirt2 = {
		backdrop = "park_bench",
		text = {text = "No need for flattery. Get up and make yourself proper."},
		name = {char = "MLI"},
		goTo = "in_flirt3",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_smitten"}
	},
	in_flirt3 = {
		backdrop = "park_bench",
		text = {text = "You start getting up as they offer you a hand, you take it and they pull you up. You stand up and steady yourself as they resume their previous position."},
		name = "Story",
		goTo = "in_flirt4",
		sprite = {char = "MLI",base = "neutral",face = "neutral_smitten"}
	},
	in_flirt4 = {
		backdrop = "park_bench",
		text = {text = "My name is Millias Aloof, and you may know me as ${MLI}. May I know what to call you?"},
		name = {char = "MLI"},
		options = {
			{choice = "${Player}", goTo = "in_Player1"},
			{choice = '"The Scatman."', goTo = "scatman"},
			{choice = "gush", goTo = "intr_gush1"}
		},
		sprite = {char = "MLI",base = "neutral",face = "neutral"},
		script = function() gameState.chars.MLI.revealed = true  end
	},
	intr_retaliate = {
		backdrop = "park_bench",
		text = {text = "Hey, did you just push me?!"},
		name ="You",
		goTo = "in_retaliate1",
		sprite = {char = "MLI",base = "neutral",face = "curious"},
		script = function() gameState.chars.MLI.status = "annoyed" end
	},
	in_retaliate1 = {
		backdrop = "park_bench",
		text = {text = "What? No, that's absurd, why would I-"},
		name = {char = "MLI"},
		goTo = "in_retaliate2",
		sprite = {char = "MLI",base = "shrug",face = "angry"}
	},
	in_retaliate2 = {
		backdrop = "park_bench",
		text = {text = "That's so rude, how could you? And then calling me clumsy!"},
		name ="You",
		goTo = "in_retaliate3",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	in_retaliate3 = {
		backdrop = "park_bench",
		text = {text = "..."},
		name = {char = "MLI"},
		goTo = "in_retaliate4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
		in_retaliate4 = {
		backdrop = "park_bench",
		text = {text = "Would you like help getting up?"},
		name = {char = "MLI"},
		goTo = "in_retaliate5",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	in_retaliate5 = {
		backdrop = "park_bench",
		text = {text = "... Fine."},
		name ="You",
		goTo = "in_retaliate6",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	in_retaliate6 = {
		backdrop = "park_bench",
		text = {text = "They offer you a hand as you take it and lift yourself off the ground."},
		name = "Story",
		goTo = "in_retaliate7",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	in_retaliate7 = {
		backdrop = "park_bench",
		text = {text = "Well, I'm ${MLI} What's your name?"},
		name = {char = "MLI"},
		goTo = "in_Player1",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"},
		script = function() gameState.chars.MLI.revealed = true end
	},
	intr_gush1 = {
		backdrop = "park_bench",
		text = {text = "You... look so cool and pretty!"},
		name ="You" ,
		goTo = "???",
		sprite = {char = "MLI",base = "face_grab",face = "shocked_smitten"},
		script = function()
			gameState.chars.MLI.status = gameState.chars.Player.events.flirtWithMLI and "smitten" or "embarrassed"
			if gameState.chars.MLI.status == "smitten" then
				gameState.chars.MLI.events.smitten = true
				story.intr_gush1.goTo = "intr_gush2"
			else
				gameState.chars.MLI.events.embarrassed = true
				story.intr_gush1.goTo = "intr_gush1_2"
			end
		end
	},
	intr_gush1_2 = {
		backdrop = "park_bench",
		text = {text = "You jump off the ground in excitement."},
		name ="Story" ,
		goTo = "intr_gush2",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"}
	},
	intr_gush2 = {
		backdrop = "park_bench",
		text = {text = "Your hair is §operfect§r and that suit looks amazing on you! And oh my gosh, your face... GAH! "},
		name ="You",
		goTo = "???",
		sprite = {char = "MLI",base = "face_grab",face = "shocked_smitten"},
		script = function()
			if gameState.chars.MLI.events.smitten then
				story.intr_gush2.goTo = "in_gush1"
			else
				story.intr_gush2.goTo = "MLI_run1"
			end
		end
	},
	in_gush1= {
		backdrop = "park_bench",
		text = {text = "Well, Thank you.. I suppose."},
		name ={char = "MLI"} ,
		goTo = "in_gush2",
		sprite = {char = "MLI",base = "face_grab",face = "surprised_look_smitten"}
	},
	in_gush2 = {
		backdrop = "park_bench",
		text = {text = "So.. what was your name?"},
		name ={char = "MLI"} ,
		goTo = "in_gush3",
		sprite = {char = "MLI",base = "arms_down",face = "wide_smitten"}
	},
	in_gush3 = {
		backdrop = "park_bench",
		text = {text = "My name's ${Player}."},
		name ="You",
		goTo = "in_gush4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	in_gush4 = {
		backdrop = "park_bench",
		text = {text = "Nice to meet you, ${Player}. I have things to do, so maybe I'll see you around, but goodbye for the meantime."},
		name = {char = "MLI"},
		goTo = "in_Player4",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	MLI_run1 = {
		backdrop = "park_bench",
		text = {text = "Ah..."},
		name ={char = "MLI"},
		goTo = "MLI_run2",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"},
		script = function() gameState.musicPlaying = false end
	},
	MLI_run2 = {
		backdrop = "park_bench",
		text = {text = "huh..."},
		name ={char = "MLI"},
		goTo = "MLI_run3",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"}
	},
	MLI_run3 = {
		backdrop = "park_bench",
		text = {text = "."},
		name ={char = "MLI"},
		goTo = "MLI_run4",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"}
	},
	MLI_run4= {
		backdrop = "park_bench",
		text = {text = ".."},
		name ={char = "MLI"},
		goTo = "MLI_run5",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"}
	},
	MLI_run5= {
		backdrop = "park_bench",
		text = {text = "..."},
		name ={char = "MLI"},
		goTo = "MLI_run6",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"}
	},
	MLI_run6= {
		backdrop = "park_bench",
		text = {text = "You watch them walk away"},
		name ="Story",
		goTo = "MLI_run7",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"},
		script = function() gameState.MLI_leaving = true end
	},
	MLI_run7 = {
		backdrop = "park_bench",
		text = {text = "Aw, I didn't even get their name."},
		name ="You",
		goTo = "go_first",
		script = function() gameState.musicPlaying = true end
	},
	intr_converse = {
		backdrop = "park_bench",
		text = {text = "So, what's your name?"},
		name ="You",
		goTo = "intr_converse_response",
		sprite = {char = "MLI",}
	},
	intr_converse_response = {
		backdrop = "park_bench",
		text = {text = "It's probably a good idea if you got up before introductions."},
		name = {char = "MLI"},
		goTo = "intr_converse_getup",
		sprite = {char = "MLI",}
	},
		intr_converse_getup = {
		backdrop = "park_bench",
		text = {text = "You bring yourself to your feet as they watch, uninterested."},
		name = "Story",
		goTo = "in_converse1",
		sprite = {char = "MLI",}
	},
	in_converse1 = {
		backdrop = "park_bench",
		text = {text = "My name is Millias Aloof. You may know me as ${MLI}. What May I know you as?"},
		name = {char = "MLI"},
		options = {
			{choice = "${Player}", goTo = "in_Player1"},
			{choice = '"The Scatman."', goTo = "scatman"}
		},
		sprite = {char = "MLI",base = "neutral",face = "neutral"},
		script = function() gameState.chars.MLI.revealed = true end
	},
	in_Player1 = {
		backdrop = "park_bench",
		text = {text = "I'm ${Player}."},
		name ="You",
		goTo = "in_Player2",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	in_Player2 = {
		backdrop = "park_bench",
		text = {text = "Charmed to meet you, ${Player}."},
		name = {char = "MLI"},
		goTo = "in_Player3",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	in_Player3 = {
		backdrop = "park_bench",
		text = {text = "I have stuff to do, maybe I'll see you around. Goodbye."},
		name = {char = "MLI"},
		goTo = "in_Player4",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
		in_Player4 = {
		backdrop = "park_bench",
		text = {text = "See you later, ${MLI}"},
		name ="You",
		goTo = "in_Player5",
		sprite = {char = "MLI",base = "neutral",face = "neutral_look_smitten"}
	},
		in_Player5 = {
		backdrop = "park_bench",
		text = {text = "You see ${MLI} walk away as you're left alone with your thoughts."},
		name ="Story",
		goTo = "go_first"
	},
	scatman = {
		backdrop = "park_bench",
		text = {text = "I'm the Scatman. Badabadabadoo"},
		name ="You",
		goTo = "scatman_resp1",
		sprite = {char = "MLI",base = "neutral",face = "curious_smirk"},
		script = function()
			gameState.chars.Player.events.scatman = true
			gameState.chars.MLI.status =  gameState.chars.Player.events.flirtWithMLI and "friendly" or "jovial"
		end
	},
	scatman_resp1 = {
		backdrop = "park_bench",
		text = {text = "Pfft, I didn't expect you to be funny"},
		name = {char = "MLI"},
		goTo = "scatman_resp2",
		sprite = {char = "MLI",base = "chin_grab",face = "laugh"}
	},
	scatman_resp2 = {
		backdrop = "park_bench",
		text = {text = "But really, what is it?"},
		name = {char = "MLI"},
		goTo = "in_Player1",
		sprite = {char = "MLI",base = "neutral",face = "curious_smirk"}
	},
	go_first = {
		backdrop = "park_bench",
		text = {text = "Where would you like to go?"},
		options = {
			{choice = "The pool", goTo = "in_pool1"},
			{choice = "A game arcade", goTo = "in_arcade1"}
		}
	},
	in_arcade1 = {
		backdrop = "arcade_machines",
		text = {text = "You spend a good amount of time playing some games in the arcade when a familiar figure appears."},
		name = "Story",
		script = function()
			if gameState.chars.MLI.revealed then
				story.in_arcade1.goTo = "in_arcade2"
			else
				story.in_arcade1.goTo = "in_arcade2_alt1"
			end
		end
	},
	in_arcade2 = {
		backdrop = "arcade_machines",
		text = {text = "Oh hey, ${MLI}. What are you doing here?"},
		name ="You",
		goTo = "in_arcade3",
		sprite = {char = "MLI",base = "arms_down",face = "surprised"}
	},
	in_arcade3 = {
		backdrop = "arcade_machines",
		text = {text = "I was going swimming in the pool, I wanted to relax with an arcade game."},
		name = {char = "MLI"},
		goTo = "in_arcade4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	in_arcade2_alt1 = {
		backdrop = "arcade_machines",
		text = {text = "Oh hey, I didn't catch your name."},
		name ="You",
		goTo = "in_arcade2_alt2",
		sprite = {char = "MLI",base = "neutral",face = "surprised"}
	},
	in_arcade2_alt2 = {
		backdrop = "arcade_machines",
		text = {text = "Oh, um.. You can call me ${MLI}."},
		name = {char = "MLI"},
		goTo = "in_arcade2_alt3",
		sprite = {char = "MLI",base = "neutral",face = "neutral"},
		script = function() gameState.chars.MLI.revealed = true  end
	},
	in_arcade2_alt3 = {
		backdrop = "arcade_machines",
		text = {text = "I'm ${Player}."},
		name = "You",
		goTo = "in_arcade4",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	in_arcade4 = {
		backdrop = "arcade_machines",
		text = {text = "While we're both here, why don't we play some games?"},
		name = {char = "MLI"},
		options = {
			{choice = "Watch them play", goTo = "arcade_watch1"},
			{choice = "Play with them", goTo = "arcade_play1"}
		},
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	arcade_watch1 = {
		backdrop = "arcade_machines",
		text = {text = "I'd like to see you play something."},
		name = "You",
		goTo = "arcade_watch2",
		sprite = {char = "MLI",base = "neutral",face = "curious"}
	},
	arcade_watch2 = {
		backdrop = "arcade_machines",
		text = {text = "Alright then, fine by me. I think I'll play Pa:pacman:-man."},
		name = {char = "MLI"},
		goTo = "arcade_watch3",
		sprite = {char = "MLI",base = "neutral",face = "curious_smirk"}
	},
	arcade_watch3 = {
		backdrop = "arcade_machines",
		text = {text = "They get in front of a machine and start the game."},
		name = "Story",
		goTo = "arcade_watch4"
	},
	arcade_watch4 = {
		backdrop = "arcade_machines",
		text = {text = "They're playing Pacman, you see Pacman himself darting around the screen, munching on some pellets and eating :ghost_vulnerable:s."},
		name = "Story",
		goTo = "arcade_watch5"
	},
	arcade_watch5 = {
		backdrop = "arcade_machines",
		text = {text = "... They're pretty good at it."},
		name = "Story",
		goTo = "arcade_watch6"
	},
	arcade_watch6 = {
		backdrop = "arcade_machines",
		text = {text = "... You're starting to wish they picked a game with a bit more action that didn't go on as long. Looks like they're almost finished though."},
		name = "Story",
		goTo = "arcade_watch7"
	},
	arcade_watch7 = {
		backdrop = "arcade_machines",
		text = {text = "I got further than usual."},
		name = {char = "MLI"},
		goTo = "arcade_exit",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	arcade_play1 = {
		backdrop = "arcade_machines",
		text = {text = "Ya sure, I wanna try that fighting game."},
		name = "You",
		goTo = "arcade_play2",
		sprite = {char = "MLI",base = "neutral",face = "curious"}
	},
	arcade_play2 = {
		backdrop = "arcade_machines",
		text = {text = "Sure thing."},
		name = {char = "MLI"},
		goTo = "arcade_play3",
		sprite = {char = "MLI",base = "neutral",face = "smirk"}
	},
	arcade_play3 = {
		backdrop = "arcade_machines",
		text = {text = "You both approach the arcade machine with imagery of the game you want to play and start it."},
		name = "Story",
		goTo = "arcade_play4",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	arcade_play4 = {
		backdrop = "arcade_machines",
		text = {text = "I don't play pvp games much, or co-op, I usually play singleplayer, so I'm kinda excited about it. Good luck, ${Player}."},
		name = {char = "MLI"},
		goTo = "arcade_play5",
		sprite = {char = "MLI",base = "neutral",face = "smirk"}
	},
	arcade_play5 = {
		backdrop = "arcade_machines",
		text = {text = "As the game starts, the screen flashes some controls, but neither of you care to read them and you start mashing buttons. They seem to be mashing buttons too, although less erratically."},
		name = "Story",
		goTo = "arcade_play6"
	},
	arcade_play6= {
		backdrop = "arcade_machines",
		text = {text = "Both your characters get knocked around a bunch, but throughout the game it seems ${MLI} has the upper hand."},
		name = "Story",
		goTo = "arcade_play7"
	},
	arcade_play7 = {
		backdrop = "arcade_machines",
		text = {text = "..."},
		name = "Story",
		goTo = "arcade_play8"
	},
	arcade_play8 = {
		backdrop = "arcade_machines",
		text = {text = "${MLI} won."},
		name = "Story",
		goTo = "arcade_play9"
	},
	arcade_play9 = {
		backdrop = "arcade_machines",
		text = {text = "That was a lot of fun, we should play together again sometime."},
		name = "Story",
		goTo = "arcade_exit",
		sprite = {char = "MLI",base = "neutral",face = "smirk"},
		script = function() gameState.chars.Player.events.playedArcade = true end
	},
	arcade_exit = {
		backdrop = "arcade_machines",
		text = {text = "I'm pretty thirsty now, so I'm going to get something from the vending machines. You wanna come with me?"},
		name = {char = "MLI"},
		options = {
			{choice = "Go with them", goTo = "arcade_vend1"},
			{choice = '"No thanks."', goTo = "arcade_end1"}
		},
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	arcade_end1 = {
		backdrop = "arcade_machines",
		text = {text = "No, I'll stay here"},
		name = "You",
		goTo = "arcade_end2",
		sprite = {char = "MLI",base = "arms_down",face = "curious"}
	},
	arcade_end2 = {
		backdrop = "arcade_machines",
		text = {text = "Oh. Alright, then. Goodbye, ${Player}."},
		name = {char = "MLI"},
		goTo = "arcade_end3",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	arcade_end3 = {
		backdrop = "arcade_machines",
		text = {text = "Goodbye."},
		name = "You",
		goTo = "arcade_end4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	arcade_end4 = {
		backdrop = "arcade_machines",
		text = {text = "You watch them walk away, and you never see them again."},
		name = "Story",
		goTo = "arcade_end5"
	},
	arcade_end5 = {
		backdrop = "arcade_machines",
		text = {text = "The end."},
		name = "Story"
	},
	arcade_vend1 = {
		backdrop = "arcade_machines",
		text = {text = "Sure, let's go."},
		name = "You",
		goTo = "arcade_vend2",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	arcade_vend2 = {
		backdrop = "arcade_machines",
		text = {text = "You walk together a remarkably long ways away from the arcade to the vending machines. Don't they know gamers get sweaty?"},
		name = "Story",
		goTo = "vend_mach1"
	},
	in_pool1 = {
		backdrop = "pool",
		text = {text = "You decide to go to the pool, and as you arrive there, you immediately see a familiar face."},
		name = "Story",
		goTo = "",
		script = function()
			if gameState.chars.MLI.revealed then
				story.in_pool1.goTo = "in_pool2"
			else
				story.in_pool1.goTo = "in_pool2_alt1"
			end
		end
	},
	in_pool2_alt1 = {
		backdrop = "pool",
		text = {text = "Oh, hi, umm..."},
		name = {char = "MLI"},
		goTo = "in_pool2_alt2",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	in_pool2_alt2 = {
		backdrop = "pool",
		text = {text = "We haven't introduced. You can call me Milly."},
		name = {char = "MLI"},
		goTo = "in_pool2_alt3",
		sprite = {char = "MLI",base = "neutral",face = "neutral_look"},
		script = function() gameState.chars.MLI.revealed = true end
	},
	in_pool2_alt3 = {
		backdrop = "pool",
		text = {text = "I'm ${Player}."},
		name = "You",
		goTo = "in_pool3",
		sprite = {char = "MLI",base = "neutral",face = "neutral_look"},
		script = function() gameState.chars.MLI.revealed = true end
	},
	in_pool2 = {
		backdrop = "pool",
		text = {text = "Oh, hello again, ${Player}."},
		name = {char = "MLI"},
		goTo = "in_pool3",
		sprite = {char = "MLI",base = "neutral",face = "smirk"}
	},
	in_pool3 = {
		backdrop = "pool",
		text = {text = "What are you doing here?"},
		name = "You",
		goTo = "in_pool4",
		sprite = {char = "MLI",base = "neutral",face = "neutral"}
	},
	in_pool3 = {
		backdrop = "pool",
		text = {text = "I like to swim here every so often."},
		name = {char = "MLI"},
		goTo = "in_pool4",
		sprite = {char = "MLI",base = "neutral",face = "neutral_look"}
	},
	in_pool3 = {
		backdrop = "pool",
		text = {text = "... Would you like to join me today?"},
		name = {char = "MLI"},
		options = {
			{choice = "Watch them swim", goTo = "pool_watch1"},
			{choice = "Go swimming", goTo = "pool_swim1"}
		},
		sprite = {char = "MLI",base = "neutral",face = "curious"}
	},
	pool_watch1 = {
		backdrop = "pool",
		text = {text = "I'd rather stay put."},
		name = "You",
		goTo = "pool_watch2",
		sprite = {char = "MLI",base = "neutral",face = "curious"}
	},
	pool_watch2 = {
		backdrop = "pool",
		text = {text = "Suit yourself, then."},
		name = {char = "MLI"},
		goTo = "pool_watch3",
		sprite = {char = "MLI",base = "neutral",face = "curious_smirk"}
	},
	pool_watch3 = {
		backdrop = "pool",
		text = {text = "As you find a place to sit and ponder on your muddy debaucle, you see ${MLI} jump into the pool with a sort of grace."},
		name = "Story",
		goTo = "pool_watch4"
	},
	pool_watch4 = {
		backdrop = "pool",
		text = {text = "You watch as they complete several laps without stopping."},
		name = "Story",
		goTo = "pool_watch5"
	},
	pool_watch5 = {
		backdrop = "pool",
		text = {text = "..."},
		name = "Story",
		goTo = "pool_watch6"
	},
	pool_watch6 = {
		backdrop = "pool",
		text = {text = "They really seem to enjoy swimming."},
		name = "Story",
		goTo = "pool_watch7"
	},
	pool_watch7 = {
		backdrop = "pool",
		text = {text = "They finally exit the water and proceed to dry themselves off, before returning to your position."},
		name = "Story",
		goTo = "pool_exit"
	},
	pool_swim1 = {
		backdrop = "pool",
		text = {text = "Sure, that sounds like fun."},
		name = "You",
		goTo = "pool_swim2",
		sprite = {char = "MLI",base = "neutral",face = "smirk"}
	},
	pool_swim2 = {
		backdrop = "pool",
		text = {text = "Let's go then."},
		name = {char = "MLI"},
		goTo = "pool_swim3",
		sprite = {char = "MLI",base = "neutral",face = "smirk"}
	},
	pool_swim3= {
		backdrop = "pool",
		text = {text = "You both make your ways to the pool. You slide in while ${MLI} jumps in excitedly."},
		name = "Story",
		goTo = "pool_swim4"
	},
	pool_swim4= {
		backdrop = "pool",
		text = {text = "Hey, you wanna race?"},
		name = {char = "MLI"},
		goTo = "pool_swim5",
		sprite = {char = "MLI",base = "arms_down",face = "curious_smirk"}
	},
	pool_swim5= {
		backdrop = "pool",
		text = {text = "Why not?"},
		name = "You",
		goTo = "pool_swim6",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	pool_swim6= {
		backdrop = "pool",
		text = {text = "The two of you begin to swim laps, but as you make it to the halfway point, ${MLI} has already reached the end of the pool and has looped back to you."},
		name = {char = "MLI"},
		goTo = "pool_swim7"
	},
	pool_swim7= {
		backdrop = "pool",
		text = {text = "Haha!"},
		name = {char = "MLI"},
		goTo = "pool_swim8",
		sprite = {char = "MLI",base = "arms_down",face = "laugh"},
	},
	pool_swim8= {
		backdrop = "pool",
		text = {text = "... Okay."},
		name = "You",
		goTo = "pool_swim9"
	},
	pool_swim9= {
		backdrop = "pool",
		text = {text = "After a few laps you get tired and return to land, ${MLI} following after one more lap."},
		name = "Story",
		goTo = "pool_swim10"
	},
	pool_swim10= {
		backdrop = "pool",
		text = {text = "That was fun, we should go swimming together more."},
		name = {char = "MLI"},
		goTo = "pool_swim11",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"},
	},
	pool_swim11= {
		backdrop = "pool",
		text = {text = "${MLI} exits the water and dries themselves offselves off before returning to you."},
		name = "Story",
		goTo = "pool_exit",
		script = function() gameState.chars.Player.events.swamInPool = true end
	},
	pool_exit = {
		backdrop = "pool",
		text = {text = "Well, I'm pretty thirsty, do you want to come with me to the vending machines?"},
		name = {char = "MLI"},
		options = {
			{choice = "Go with them", goTo = "pool_vend1"},
			{choice = '"No thanks."', goTo = "pool_end1"}
		},
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	pool_end1 = {
		backdrop = "pool",
		text = {text = "No thanks, you go ahead."},
		name = "You",
		goTo = "pool_end2",
		sprite = {char = "MLI",base = "arms_down",face = "surprised"}
	},
	pool_end2 = {
		backdrop = "pool",
		text = {text = "Sure. Goodbye, ${Player}."},
		name = {char = "MLI"},
		goTo = "pool_end3",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	pool_end3 = {
		backdrop = "pool",
		text = {text = "You see them leave, and you recline back in your seat, never talking to ${MLI} again."},
		name = "Story",
		goTo = "pool_end4"
	},
	pool_end4 = {
		backdrop = "pool",
		text = {text = "The end."},
		name = "Story"
	},
	pool_vend1 = {
		backdrop = "pool",
		text = {text = "Sure, I could use a drink."},
		name = "You",
		goTo = "pool_vend2",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"},
	},
	pool_vend2 = {
		backdrop = "pool",
		text = {text = "You both take the relatively short walk to the vending machines. Convenient."},
		name = "Story",
		goTo = "vend_mach1"
	},
	vend_mach1 = {
		backdrop = "vending_machines",
		text = {text = "What would you like to get?"},
		name = {char = "MLI"},
		options = {
			{choice = "Iced tea", goTo = "vend_mach2"},
			{choice = "Some cola", goTo = "vend_mach2"},
			{choice = "orange pop", goTo = "vend_mach2"},
			{choice = '"Will you hate me?"', goTo = "drink_hate"},
		},
		sprite = {char = "MLI",base = "neutral",face = "smirk"},
	},
	drink_hate = {
		backdrop = "vending_machines",
		text = {text = "Huh? No, why would I.. Just get whatever."},
		name = {char = "MLI"},
		goTo = "vend_mach3",
		sprite = {char = "MLI",base = "neutral",face = "curious"},
	},
	vend_mach2 = {
		backdrop = "vending_machines",
		text = {text = "We'll get that then."},
		name = {char = "MLI"},
		goTo = "vend_mach3",
		sprite = {char = "MLI",base = "neutral",face = "smirk"},
	},
	vend_mach3 = {
		backdrop = "vending_machines",
		text = {text = "You both buy your beverages and drink them."},
		name = "Story",
		goTo = "vend_mach4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
	},
	vend_mach4 = {
		backdrop = "vending_machines",
		text = {text = "So, I worked up an appetite, would you like to go somewhere to eat with me?"},
		name = {char = "MLI"},
		options = {
			{choice = "Cat Cafe", goTo = "cat_cafe1"},
			{choice = "Soup Way", goTo = "soup_way1"},
		},
		sprite = {char = "MLI",base = "arms_down",face = "neutral"},
	},
	cat_cafe1 = {
		backdrop = "vending_machines",
		text = {text = "How about that cat cafe?"},
		name = "You",
		goTo = "cat_cafe2",
		sprite = {char = "MLI",base = "arms_down",face = "shocked_smitten"},
	},
	cat_cafe2 = {
		backdrop = "vending_machines",
		text = {text = "Ya, we could go there... If you want."},
		name = {char = "MLI"},
		goTo = "cat_cafe3",
		sprite = {char = "MLI",base = "arms_down",face = "surprised_look_smitten"},
	},
	cat_cafe3 = {
		backdrop = "cat_cafe_out",
		text = {text = "The two of you walk together to the cat cafe, and you realize there's indoor and outdoor seating."},
		name = "Story",
		options = {
			{choice = "Eat outside", goTo = "cat_cafe_out1"},
			{choice = "Eat inside", goTo = "cat_cafe_in1"},
		},
	},
	cat_cafe_out1 = {
		backdrop = "cat_cafe_out",
		text = {text = "Let's eat outside."},
		name = "You",
		goTo = "cat_cafe_out2",
		sprite = {char = "MLI",base = "arms_down",face = "surprised"},
	},
	cat_cafe_out2 = {
		backdrop = "cat_cafe_out",
		text = {text = "Oh. Okay, fine."},
		name = {char = "MLI"},
		goTo = "cat_cafe_out3",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"},
	},
	cat_cafe_out3 = {
		backdrop = "cat_cafe_out",
		text = {text = "Shortly after you both take your seats, a waitress comes over and takes your order."},
		name = "Story",
		goTo = "cat_cafe_out4"
	},
	cat_cafe_out4 = {
		backdrop = "cat_cafe_out",
		text = {text = "I've actually been thinking about going here myself."},
		name = {char = "MLI"},
		goTo = "cat_cafe_out5",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
	},
	cat_cafe_out5 = {
		backdrop = "cat_cafe_out",
		text = {text = "The waitress returned with the food."},
		name = "Story",
		goTo = "cat_cafe_out6",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"},
	},
	cat_cafe_out6 = {
		backdrop = "cat_cafe_out",
		text = {text = "This is nice."},
		name = {char = "MLI"},
		goTo = "cat_cafe_out7",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"},
	},
	cat_cafe_out7 = {
		backdrop = "cat_cafe_out",
		text = {text = "You both take your time enjoying your meal, and finish as it starts getting dark."},
		name = "Story",
		goTo = "cat_cafe_exit",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	cat_cafe_in1 = {
		backdrop = "cat_cafe_out",
		text = {text = "Let's eat inside."},
		name = "You",
		goTo = "cat_cafe_in2",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"},
	},
	cat_cafe_in2 = {
		backdrop = "cat_cafe_out",
		text = {text = "Sure. After you."},
		name = {char = "MLI"},
		goTo = "cat_cafe_in3",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"},
	},
	cat_cafe_in3 = {
		backdrop = "cat_cafe_in",
		text = {text = "You both walk into the cafe as the waitress greets you and you're escorted to your seats. You both finish ordering when you notice ${MLI} looking in some other direction."},
		name = "Story",
		goTo = "cat_cafe_in4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
	},
	cat_cafe_in4 = {
		backdrop = "cat_cafe_in",
		text = {text = "Oh, it's just... That cat is looking here."},
		name = {char = "MLI"},
		goTo = "cat_cafe_in5",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
	},
	cat_cafe_in5 = {
		backdrop = "cat_cafe_in",
		text = {text = "The aformentioned cat suddenly starts walking over to your table, and rubs itself against ${MLI}'s legs."},
		name = "Story",
		goTo = "cat_cafe_in6",
		sprite = {char = "MLI",base = "arms_down",face = "wide_smitten"},
	},
	cat_cafe_in6 = {
		backdrop = "cat_cafe_in",
		text = {text = "The waitress brings over your food, commenting on how the cat clearly likes the two of you. They leave you to eat the food and the cat looks up at you."},
		name = "Story",
		options = {
			{choice = "Pet the cat",goTo = "cat_cafe_pet"},
			{choice = "Continue eating",goTo = "cat_cafe_in7"}
		},
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
	},
	cat_cafe_pet = {
		backdrop = "cat_cafe_in",
		text = {text = "You pat its head, scratch their chin, rub its back, I dunno, it's a cat. You pet it. ${MLI} seems happy, also petting the cat while seeing you pet them."},
		name = "Story",
		goTo = "cat_cafe_in7",
		sprite = {char = "MLI",base = "arms_down",face = "smirk_smitten"},
		script = function() gameState.chars.Player.events.petCats = true end
	},
	cat_cafe_in7 = {
		backdrop = "cat_cafe_in",
		text = {text = "You go back to eating your food and the cat walks back to its post."},
		name = "Story",
		goTo = "cat_cafe_in8",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_smitten"}
	},
	cat_cafe_in8 = {
		backdrop = "cat_cafe_in",
		text = {text = "I'd be interested in going back here with you again sometime."},
		name = {char = "MLI"},
		goTo = "cat_cafe_in9",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"}
	},
	cat_cafe_in9 = {
		backdrop = "cat_cafe_out",
		text = {text = "After finishing your food, you both make your way outside."},
		name = "Story",
		goTo = "cat_cafe_exit",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	cat_cafe_exit = {
		backdrop = "cat_cafe_out",
		text = {text = "Would you like to go see a movie with me?"},
		name = {char = "MLI"},
		options = {
			{choice = '"No thanks."', goTo = "cat_cafe_end1"},
			{choice = "Go to the theater", goTo = "cat_cafe_theater1"}
		},
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	cat_cafe_end1 = {
		backdrop = "cat_cafe_out",
		text = {text = "No thanks."},
		name = "You",
		goTo = "cat_cafe_end2",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	cat_cafe_end2 = {
		backdrop = "cat_cafe_out",
		text = {text = "Very well then. Hope to see you again, ${Player}."},
		name = {char = "MLI"},
		goTo = "cat_cafe_end3",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	cat_cafe_end3= {
		backdrop = "cat_cafe_out",
		text = {text = "Goodbye, ${MLI}."},
		name = "You",
		goTo = "cat_cafe_end4",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	cat_cafe_end4 = {
		backdrop = "cat_cafe_out",
		text = {text = "You both leave and throughout the future you continue to be friends, doing.. §o*Checks notes*§r"},
		name = "Story",
		goTo = "cat_cafe_end5",
		script = function()
			story.cat_cafe_end5.text = tallyEvents()
		end
	},
	cat_cafe_end5 = {
		backdrop = "cat_cafe_out",
		text = "???",
		name = "Story",
		goTo = "cat_cafe_end6"
	},
	cat_cafe_end6 = {
		backdrop = "cat_cafe_out",
		text = "The end.",
		name = "Story"
	},
	cat_cafe_theater1 = {
		backdrop = "cat_cafe_out",
		text = "Sure, let's go.",
		name = "You",
		goTo = "cat_cafe_theater2"
	},
	cat_cafe_theater2 = {
		backdrop = "cat_cafe_out",
		text = "You both depart and start to make your way toward the theater",
		name = "Story",
		goTo = "cat_cafe_theater3"
	},
	cat_cafe_theater3 = {
		backdrop = "cat_cafe_out",
		text = "Is there a certain movie you want to watch?",
		name = "You",
		goTo = "cat_cafe_theater4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	cat_cafe_theater4 = {
		backdrop = "cat_cafe_out",
		text = "No, not particularly...",
		name = {char = "MLI"},
		goTo = "theater1",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"}
	},
	soup_way1 = {
		backdrop = "vending_machines",
		text = {text = "Let's eat at Soup Way."},
		name = "You",
		goTo = "soup_way2",
		sprite = {char = "MLI",base = "arms_down",face = "curious"}
		},
	soup_way2 = {
		backdrop = "vending_machines",
		text = {text = "Sure, that sounds good."},
		name = {char = "MLI"},
		goTo = "soup_way3",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
		},
	soup_way3 = {
		backdrop = "soup_way",
		text = {text = "You both walk into Soup Way and order, before sitting down."},
		name = "You",
		goTo = "soup_way4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
		},
	soup_way4 = {
		backdrop = "soup_way",
		text = {text = "Your food is made and you both take it and sit down and eat. The meal is otherwise uneventful."},
		name = "You",
		goTo = "soup_way5",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
		},
	soup_way5 = {
		backdrop = "soup_way",
		text = {text = "You finish your food and both dawdle before deciding to leave."},
		name = "You",
		goTo = "soup_way_exit",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
		},
	soup_way_exit = {
		backdrop = "soup_way",
		text = {text = "Would you like to go see a movie with me?"},
		name = {char = "MLI"},
		options = {
			{choice = '"No thanks."', goTo = "soup_way_end1"},
			{choice = "Go to the theater", goTo = "soup_way_theater1"}
		},
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"}
	},
	soup_way_end1 = {
		backdrop = "soup_way",
		text = {text = "No thanks."},
		name = "You",
		goTo = "soup_way_end2",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
		},
	soup_way_end2 = {
		backdrop = "soup_way",
		text = {text = "Very well then. I hope to see you again, ${Player}."},
		name = {char = "MLI"},
		goTo = "soup_way_end3",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
		},
	soup_way_end3 = {
		backdrop = "soup_way",
		text = "Goodbye, ${MLI}.",
		name = "You",
		goTo = "soup_way_end4"
	},
	soup_way_end4 = {
		backdrop = "soup_way",
		text = {text = "You both leave and throughout the future you continue to be friends, doing.. §o*Checks notes*§r"},
		name = "Story",
		goTo = "soup_way_end5",
		script = function()
			story.soup_way_end5.text = tallyEvents()
		end
	},
	soup_way_end5 = {
		backdrop = "soup_way",
		text = "???",
		name = "Story",
		goTo = "soup_way_end6"
	},
	soup_way_end6 = {
		backdrop = "soup_way",
		text = "The end.",
		name = "Story"
	},
	soup_way_theater1 = {
		backdrop = "soup_way",
		text = "Sure, let's go.",
		name = "You",
		goTo = "soup_way_theater2"
	},
	soup_way_theater2 = {
		backdrop = "soup_way",
		text = "You both depart and start to make your way toward the theater.",
		name = "Story",
		goTo = "soup_way_theater3"
	},
	soup_way_theater3 = {
		backdrop = "soup_way",
		text = "Is there a certain movie you want to watch?",
		name = "You",
		goTo = "soup_way_theater4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	soup_way_theater4 = {
		backdrop = "soup_way",
		text = "No, not particularly...",
		name = {char = "MLI"},
		goTo = "soup_way_theater5",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"}
	},
	soup_way_theater5 = {
		backdrop = "soup_way",
		text = "...",
		name = "You",
		goTo = "theater1",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"}
	},
	theater1 = {
		backdrop = "theater",
		text = "You both eventually arrive at the theater.",
		name = "Story",
		goTo = "theater2",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look"}
	},
	theater2 = {
		backdrop = "theater",
		text = "What do you think we should watch?",
		name = {char = "MLI"},
		options = {
			{choice = "Some romance movie", goTo = "theater3"},
			{choice = "An action movie", goTo = "theater3"}
		},
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	theater3 = {
		backdrop = "theater",
		text = "Sure. Let's go in.",
		name = {char = "MLI"},
		goTo = "theater4",
		sprite = {char = "MLI",base = "arms_down",face = "neutral"}
	},
	theater4 = {
		backdrop = "theater",
		text = "You both walk into the theater room, which seems to be largely empty, and take your seats. After a short wait, the movie starts.",
		name = "Story",
		goTo = "theater5"
	},
	theater5 = {
		backdrop = "theater",
		text = "You both watch the movie, it lasts about as long as movies last...",
		name = "Story",
		goTo = "theater6"
	},
	theater6 = {
		backdrop = "theater",
		text = "You didn't particularly like the movie. But you enjoyed watching it with ${MLI} regardless.",
		name = "Story",
		goTo = "theater7"
	},
	theater7 = {
		backdrop = "theater",
		text = "That was okay..",
		name = {char = "MLI"},
		options = {
			{choice = "Ask to date", goTo = "theater_date1"},
			{choice = "Ask to be friends", goTo = "theater_friend1"}
		},
		sprite = {char = "MLI",base = "neutral",face = "neutral_look_smitten"}
	},
	theater_date1 = {
		backdrop = "theater",
		text = "Would you want to be in a romantic relationship with me?",
		name = {char = "MLI"},
		goTo = "theater_date2",
		sprite = {char = "MLI",base = "arms_down",face = "surprised_smitten"}
	},
	theater_date2 = {
		backdrop = "theater",
		text = "???",
		name = {char = "MLI"},
		goTo = "observatory1",
		sprite = {char = "MLI",base = "arms_down",face = "surprised_look_smitten"},
		script = function()
			local embrr = gameState.chars.MLI.events.embarrassed
			story.theater_date2.text = embrr and "Actually, I'd rather we just be friends.." or "I would like that actually, ya.."
			gameState.chars.MLI.relationship = embrr and "friends" or "significant others"
			gameState.chars.MLI.dating = not embrr
		end
	},
	theater_friend1 = {
		backdrop = "theater",
		text = "Would you like to be friends with me?",
		name = "You",
		goTo = "theater_friend2",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_smitten"}
	},
	theater_friend2 = {
		backdrop = "theater",
		text = "Yes, I would like that.",
		name = {char = "MLI"},
		goTo = "observatory1",
		sprite = {char = "MLI",base = "arms_down",face = "smirk_smitten"}
	},
	observatory1 = {
		backdrop = "theater",
		text = "There's a place I want you to see, actually, come with me.",
		name = {char = "MLI"},
		goTo = "observatory2",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	observatory2 = {
		backdrop = "observatory",
		text = "${MLI} takes your hand and brings you somewhere, you're unsure where you're going until you see a big blossoming tree in the center of purple glass some acacia structures.",
		name = "Story",
		goTo = "observatory3",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	observatory3 = {
		backdrop = "observatory",
		text = "I just really like this place...",
		name = "Story",
		goTo = "observatory4",
		sprite = {char = "MLI",base = "arms_down",face = "smirk"}
	},
	observatory4 = {
		backdrop = "observatory",
		text = "You both sit down in the grass for some time, taking in the scenery...",
		name = "Story",
		goTo = "???",
		sprite = {char = "MLI",base = "arms_down",face = "neutral_look_smitten"},
		script = function() story.observatory4.goTo = gameState.chars.MLI.dating and "observatory_kiss" or "observatory5" end
	},
	observatory_kiss = {
		backdrop = "observatory",
		text = "${MLI} looks at you, you look at them, and they lean in and you kiss.",
		name = "Story",
		goTo = "observatory5"
	},
	observatory5 = {
		backdrop = "observatory",
		text = {text = "Eventually, you both leave and throughout the future you continue to hang out, doing.. §o*Checks notes*§r"},
		name = "Story",
		goTo = "observatory6",
		script = function()
			story.observatory6.text = tallyEvents()
		end
	},
	observatory6= {
		backdrop = "observatory",
		text = "???",
		name = "Story",
		goTo = "TRUE_END"
	},
	TRUE_END = {
		backdrop = "observatory",
		text = {text = "The end."},
		name = "Story",
		goTo = "credits1"
	},
	credits1 = {
		backdrop = "observatory",
		text = "Thank you for playing! Credits to the builders of The Plaza for my backdrops, and GNamimates for GNUI, the GUI library this game is built with. As well as the hellpers who paste code snippets, like the one I got the note playing from. Virtually everything else is my own work.",
		name = "MxDuck",
		sprite = {char = "mxduck",base = "mxduck",face = "none"},
	},
}


GAMESTATE = gameState
local function insertPathNode(node,path)
	local path = path or gameState.path
	for i=#path+1,gameState.currStep+1,-1 do
		TREMOVE(path,i)
	end
	TINSERT(path,{node = node})
end



local function sumTextLengths(box)
	local num,t = 0,box.TextLengths
	for _,v in ipairs(t) do
		num = num + v
	end
	return num
end

local screen = GNUI.getScreenCanvas()
local txtrs = textures:getTextures()
local defNnsc = GNUI.newNineslice(defTxtr):setOpacity(.5):setColor(0,0,0,.5):setOpacity(.9):setRenderType("TRANSLUCENT")
local backdropSlice = GNUI.newNineslice(textures["assets.park_bench"])--:setRenderType("blurry")
local MillySprite = GNUI.newNineslice(milly)
local canvas = newBox(screen):setAnchor(0,0,1,1):setZMul(-200)
local scene = newBox(canvas):setAnchor(.5,.5)

local backdrop  = newBox(scene):setNineslice(backdropSlice)
	:setAnchor(.5,.5)
	local sprites = newBox(scene)
	:setTextOffset(0,-5)
	:setAnchor(.5,1)
	:setNineslice(MLI_body)
local face_sprite = newBox(sprites)
	:setAnchor(24/64,6.9/64,34/64,20.65/64)
	:setNineslice(MLI_face)


local millyDim = vec(0,-200,200,0)

local dialog = newBox(scene):setAnchor(.5,1)
	:setNineslice(defNnsc)
	local dialog_text = newBox(dialog)
	:setText(testTxt)
	:setTextBehavior("WRAP")
	:setAnchor(0,0,1,1)
	:setDimensions(4,4,-4,-4)

	local dialog_scale = 150
	local tag_name = "Milly (Millias Aloof)"

local nametag = newBox(dialog)
	:setAnchor(0,-.42,.4,-.02)
local nametag_sprite = newBox(nametag)
	:setAnchor(0,0,0,1)
	:setNineslice(defNnsc:copy())
local nametag_text = newBox(nametag)
	:setAnchor(0.05,0.5,0.05,.5)
	:setTextBehavior("NONE")
	:setTextAlign(0,.4)
	:setText(tag_name)
	:setFontScale(1)

local options = newBox(scene)
	:setAnchor(.5,0,.5,0)
	:setDimensions(-110,0,110,80)



local nextNode

local optButtons = {}
for i=1,4 do
 local btn = Button.new(options)
---@type GNUI.InputEvent
	btn.BUTTON_DOWN:register(function ()
		local currNode = gameState.path[gameState.currStep].node
		local MLI = gameState.chars.MLI
		local node = story[currNode.."_"..MLI.status] or story[currNode]
		nextNode(node.options[i].goTo)

  -- clicked
end)
btn:setAnchor(0,0+(i-1)*.25,1,.25*i)
:setPos(0,6)
TINSERT(optButtons,btn)
end

local function hoveringOptions()
	for i=1,4 do
		if optButtons[i].isCursorHovering then
			return true
		end
	end
	return false
end

local main_menu = newBox(canvas)
	:setAnchor(0,0,1,1)
	:setNineslice(defNnsc:copy():setVisible(false))

menu_backdrop = newBox(main_menu)
	:setAnchor(.5,.5)
	:setNineslice(GNUI.newNineslice(backdrops.observatory))

 local menuSections = {
	preferences = newBox(main_menu):setAnchor(0,0,1,1),
	save = newBox(main_menu):setAnchor(0,0,1,1),
	load = newBox(main_menu):setAnchor(0,0,1,1),
	info = newBox(main_menu):setAnchor(0,0,1,1)
 }
for i,v in pairs(menuSections) do
	newBox(v):setText(i):setFontScale(3):setPos(0,0):setTextEffect("OUTLINE"):setAnchor(0.5,0):setTextAlign(0,0)
end

do
	local info = newBox(menuSections.info)
	info:setAnchor(.5,.5):setDimensions(-32,-96,160,96):setNineslice(GNUI.newNineslice(textures["GNUI.theme.gnuiTheme"],13,3,17,7, 2,2,2,2))
	newBox(info):setAnchor(0,0,1,1):setDimensions(5,5,-5,-5):setText("A short visual novel dating sim, made as a submission for the second Figura avatar contest of Cold theme.\n\nMade by: MxDuck\n\nLibraries:\nGNUI: GNamimates\n\nBuilders of The Plaza: backdrops")
end
 local node = story[gameState.path[gameState.currStep]]

 local function processText(txt)
 local tab = type(txt) == "table"
 local text = tab and txt.text or txt
		text = string.gsub(string.gsub(text,"${Player}",gameState.chars.Player.revealed and gameState.chars.Player.name),"${MLI}",gameState.chars.MLI.revealed and gameState.chars.MLI.name)
	if tab then
		txt.text = text
		text = txt
	end
	return text
end

local function setNode(step,ignoreScript)
	if gameState.MLI_leaving then
		gameState.MLI_leaving = false
		sprites:setPos(0,0)
	end
	local path = gameState.path
	step = CLAMP(step,1,#path)
	local pathStep = path[step]
	local nodeID = pathStep.node
	local origNode = path[MAX(step-1,1)]
	gameState.musicPlaying = origNode.musicPlaying
	gameState.chars = deepCopyTable(origNode.chars ) or gameState.chars
	gameState.currStep = step
	currentNode = nodeID
	local node = story[nodeID]
	local name = ""
	local nName = node.name
	local nodeChar
	local nodeOpt = node.options
	if not ignoreScript and node.script then
		node.script()
	end
	music.playing = gameState.musicPlaying
	if nodeOpt and #nodeOpt >0 then
		options:setVisible(true)
		for i = 1,4 do
			local opt = nodeOpt[i]
			local btn = optButtons[i]
			if opt then
			btn:setText(processText(opt.choice))
			end
			btn:setVisible(not not opt)
			btn:release()
			btn.BUTTON_CHANGED:invoke(false,btn.isCursorHovering)
		end
	else
		options:setVisible(false)
	end
	if type(nName) == "table" and nName.char then
		nodeChar = gameState.chars[nName.char]
		name = nodeChar.revealed and nodeChar.name or "???"
	else
		name = type(nName) == "string" and nName or ""
	end
	if (node.text and node.text.text == "The end.") or node.text == "The end."  then dialog_scale = 30 else dialog_scale = 150 end
	nametag_text:setText(name)
	dialog_text:setText(processText(node.text))
	backdropSlice:setTexture(backdrops[node.backdrop or "def"] or defTxtr)
	local sprite = node.sprite
	sprites:setVisible(not not sprite)

	if sprite then
		local bd = poses[sprite.base or "neutral"]
		MLI_body:setUV((bd-1)*64,0,bd*64-1,64)
		if sprite.face == "none" then
			MLI_face:setVisible(false)
		else
			local fc = faces[(sprite.face or "neutral").."_"..(gameState.chars.MLI.status or "nvm")] or faces[sprite.face or "neutral"]
			MLI_face:setUV((fc-1)*10,0,fc*10-1,13):setVisible(true)
		end
	end
	pathStep.chars = deepCopyTable(gameState.chars)
	pathStep.musicPlaying = gameState.musicPlaying
end

function nextNode(nodeID)
	local _nodeID = id .."_"..gameState.chars.MLI.status
	local node = story[_nodeID]
	local nodeID = node and _nodeID or nodeID
	node = story[nodeID]
	if not nodeID or not node then host:setActionbar("Ah dang, "..tostring(nodeID).." is bad.") return  end
	local path = gameState.path
	insertPathNode(nodeID,path)
	setNode(#path)
end

-- setNode(1)

local function forward()
 if not game.started or not game.playing or menu_state then return  menu_state end
 local curStep = gameState.currStep
 local next = story[gameState.path[curStep].node]
 if #gameState.path > curStep then
  setNode(curStep + 1)
 elseif next.goTo then
  nextNode(next.goTo)
 end
 return true
end

local function backward()
 if not game.started or not game.playing or menu_state then return  menu_state end
 local curStep = gameState.currStep
 local next = story[gameState.path[curStep].node]
  setNode(curStep -1)
 return true
end

for i,v in pairs(continues) do
 v:setOnPress(forward)
end

for i,v in pairs(backs) do
 v:setOnPress(backward)
end

for i=1,4 do
	keybinds:fromVanilla(movement[i]):onPress(function() return menu_state or game.started and game.playing end)
end

function events.MOUSE_SCROLL(dlt)
	if not game.started or not game.playing or host:isChatOpen() or menu_state then return menu_state end
	if dlt > 0 then
		backward()
	elseif dlt < 0 then
		forward()
	else
	--teeheehee, you found me! dlt is 0  sometimes.
	end
	return true
end


local toggleKey = keybinds:newKeybind("Toggle Game Screen","key.keyboard.grave.accent")


local warning = newBox(screen)
	:setAnchor(.5,.5)
	:setTextBehavior("NONE")
	:setTextAlign(.5,.5)
	:setFontScale(2)
	:setTextEffect("OUTLINE")

local function selectMenuSection(part)
	for i,v in pairs(menuSections) do
		v:setVisible(i == part)
	end
end

local function toggleMainMenu(bool)
	menu_state = bool
	main_menu.Nineslice:setOpacity(game.started and .4 or 1)
	main_menu:setVisible(bool)
	menu_backdrop:setVisible(not game.started)

	selectMenuSection(game.started and "save" or "preferences")
	scene:setCanCaptureCursor(not bool)
end


local function toggleGame(bool,script)
	if type(bool) ~= "boolean" then
		game.playing = not game.playing
	else
		game.playing = bool
	end
	music.playing = bool
	canvas:setVisible(game.playing)
	scene:setVisible(game.started)
	warning:setVisible(not game.playing)
	toggleMainMenu(not game.started and bool)
	host:setUnlockCursor(game.playing)
	renderer:setRenderHUD(not game.playing)
	options:setVisible(false)
	if game.started then
		setNode(gameState.currStep,not script)
	end
end
local function startGame()
	main_menu.Nineslice:setVisible(true)
	game.started = true
	toggleGame(true,true)
end

toggleGame(false)
toggleKey:setOnPress(function() toggleGame(not game.playing) end)
warning:setText("Get somewhere safe before starting the game! \nPress ' "..toggleKey:getKeyName().." ', (key "..toggleKey:getID().." or grave) when you're ready!\n(arrow keys, spacebar or scroll to continue)\n(right click to toggle menu)")

local menuButtons = {
	save  ={
		btn = Button.new(main_menu,"none")
			:setAnchor(0,.35,0,.4),
		txt = {text = "New Game",color = "#ffffff"}
	},
	load ={
		btn =Button.new(main_menu,"none")
			:setAnchor(0,.4,0,.45),
		txt = {text = "Load Game",color = "#ffffff"}
	},
	preferences ={
		btn = Button.new(main_menu,"none")
			:setAnchor(0,.45,0,.5),
		txt = {text = "Preferences",color = "#ffffff"}
	},
	info ={
		btn = Button.new(main_menu,"none")
			:setAnchor(0,.5,0,.55),
		txt = {text = "Info",color = "#ffffff"}
	}
}
menuButtons.save.btn.PRESSED:register(function() if not game.started then startGame() menuButtons.save.txt.text = "Save Game" end end)

local function setVolume(id,num)
	settings[id] = num/100
	applySettings()
end

local volumeSliders = {
	volume_fx = Slider.new(false,0,100,1,settings.volume_fx*100,menuSections.preferences,true):setAnchor(.5,.4,.9,.5):setText("effects"),
	volume_voice = Slider.new(false,0,100,1,settings.volume_voice*100,menuSections.preferences,true):setAnchor(.5,.52,.9,.62):setText("voice"),
	volume_music = Slider.new(false,0,100,1,settings.volume_music*100,menuSections.preferences,true):setAnchor(.5,.64,.9,.74):setText("music")
}

for i,s in pairs(volumeSliders) do
	s.VALUE_CHANGED:register(function(v)
		setVolume(i,v)
	end)
	s:setTextEffect("OUTLINE"):setFontScale(2)
end
volumeSliders.volume_voice.BUTTON_UP:register(function()
	playSound("MLI_HMPH",1.3,settings.volume_voice)
	saveSettings()
end)

local saveBoxes,loadBoxes = {},{}

local function loadSaveTextures()
	for i=1,6 do
		local txtr = retrieveSaveTexture(i)
		saveBoxes[i].Nineslice:setTexture(txtr)
		loadBoxes[i].Nineslice:setTexture(txtr)
	end
end

do
	local sv = 	menuSections.save
	local ld = menuSections.load
	local cnt = 0
	for y=1,2 do
		for x=1,3 do
			cnt = cnt + 1
			local i = cnt
			local anc = vec(.5+x/10+(x-1)/40,.2+y/10+(y-1)/40,.6+x/10+(x-1)/40,.3+y/10+(y-1)/40)
			local ns = defNnsc:copy():setColor(1,1,1)
			local svBox = Button.new(sv,"none"):setAnchor(anc):setNineslice(ns)
			local ldBox = Button.new(ld,"none"):setAnchor(anc):setNineslice(ns:copy())
			TINSERT(saveBoxes,svBox)
			TINSERT(loadBoxes,ldBox)
			svBox.PRESSED:register(function() saveGameState(i) loadSaveTextures() end)
			ldBox.PRESSED:register(function() loadGameState(i) startGame()  end)
			svBox.BUTTON_CHANGED:register(function(prs,hov) if hov then svBox:setDimensions(-6,-6,6,6) else svBox:setDimensions(0,0) end end)
			ldBox.BUTTON_CHANGED:register(function(prs,hov) if hov then ldBox:setDimensions(-6,-6,6,6) else ldBox:setDimensions(0,0) end end)
		end
	end
	loadSaveTextures()
end



for i,v in pairs(menuButtons) do
	local btn = v.btn
	local txt = newBox(btn):setPos(4,0):setText(v.txt):setAnchor(0,.5):setTextEffect("OUTLINE"):setTextBehavior("NONE"):setFontScale(1.5):setTextAlign(0,.5)
	btn:setDimensions(0,0,110,0)
	btn.BUTTON_CHANGED:register(function(prs,hov) v.txt.color = hov and "#d077ff" or "#ffffff" txt:setText(v.txt)  end )
	btn.PRESSED:register(function() selectMenuSection(i) end)
end

rightclick:setOnPress(function() if not game.started then return end toggleMainMenu(not menu_state) end)


local leavePos = 0
function events.tick()
	local ws = GETWINDOWSIZE()
	local gs = GETGUISCALE()
	local sws = ws/gs

	local maxWidth = MIN(400, ws.x / 2) - 2
	local maxHeight = MIN(maxWidth * 0.4, ws.y * 0.2)
	local scaledWidth = MIN(maxWidth, maxHeight / 0.4) / gs
	--scene+backdrop
	local sz = (sws.y + 2) / 2
	local x, y = -sz, sz
	local gameDims = vec(-scaledWidth, x, scaledWidth, y)
	local bckdrpDims = vec(x * 2.57, x, y * 2.57, y)
	scene:setDimensions(gameDims)
	backdrop:setDimensions(bckdrpDims)
	menu_backdrop:setDimensions(bckdrpDims)
	--dialog

	local dD = vec(-scaledWidth, -scaledWidth * 0.4, scaledWidth, 0)

	dialog:setDimensions(dD)
	dialog_text:setFontScale(scaledWidth / dialog_scale)
	nametag_text:setFontScale(scaledWidth / 80)

	local tag_length = sumTextLengths(nametag_text)
	nametag_sprite:setAnchor(0,0,.017*tag_length+ (1/scaledWidth*7*math.sign(tag_length)),1)

	--sprites
	local dim = (dD.yw - dD.xz):applyFunc(ABS)
	local spDim = millyDim*(scaledWidth/150)
	sprites:setDimensions(spDim)

	if gameState.MLI_leaving then
		leavePos = leavePos + math.pi
		sprites:setPos(leavePos,0)
		sprites:setDimensions(spDim + vec(leavePos,10,leavePos,10))
	else
		leavePos = 0
	end
end
