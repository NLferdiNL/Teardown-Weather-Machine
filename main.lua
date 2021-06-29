#include "datascripts/color4.lua"
#include "scripts/utils.lua"
#include "scripts/savedata.lua"
#include "scripts/ui.lua"
#include "scripts/menu.lua"
#include "datascripts/inputList.lua"

local stormCloudGroupClass = {
	lifetime = 10,
	cloudSpawnCount = 35,
	spawnTimerMax = 20 / 10,
	spawnTimer = 0,
	pos = nil,
	activeClouds = 0,
	clouds = {},
	cloudRange = 15,
}

local cloudClass = {
	active = true,
	pos = nil,
	lifetime = 2,
	struck = false,
	strikeLifetime = 2.5,
	strikePower = 2,
	strikeOffsets = {},
}

local stormClouds = {}
local stormCloudIndex = 1
local stormCloudsMaxIndex = 5
local stormCloudHeight = 18

local strikesToUiSound = 0

local justPlacedTimer = 0
local justPlacedTimerMax = 2
--local justPlacedPos = nil
--local justPlacedUiCircleMaxSize = 20

local toolSelected = false

local announcer_storm_created_sfx = "snd/warning_lightning_storm_created.ogg"
local rumbleSounds = 4
local rumbleSoundsIndex = 1

stormCloudGroupClass.spawnTimerMax = stormCloudGroupClass.lifetime / stormCloudGroupClass.cloudSpawnCount

local circleSprite = nil

local rtsCameraCircleCount = 8
local rtsCameraCircleMaxSize = 40
local rtsCameraActive = GetBool("level.rtsCameraActive") or false

function init()
	saveFileInit()
	--menu_init()
	
	circleSprite = LoadSprite("sprites/circle.png")
	
	--[[local loadedRumbleSounds = {}
	
	for i = 1, rumbleSounds do
		loadedRumbleSounds[i] =  LoadSound("snd/rumble0" .. i .. ".ogg")
	end
	
	rumbleSounds = loadedRumbleSounds]]--
	
	RegisterTool("weathermachine", "Weather Machine", "MOD/vox/tool.vox")
	SetBool("game.tool.weathermachine.enabled", true)
end

function tick(dt)
	--menu_tick(dt)
	rtsCameraActive = GetBool("level.rtsCameraActive") or false
	
	handleAllStormCloudGroups(dt)
	
	if justPlacedTimer > 0 then
		justPlacedTimer = justPlacedTimer - dt
	end
	
	if GetString("game.player.tool") ~= "weathermachine" then
		return
	end
	
	local cameraTransform = GetCameraTransform()
	
	local forwardPos = TransformToParentPoint(cameraTransform, Vec(0, 0, -1))
	local playerPos = TransformToParentPoint(cameraTransform, Vec(0, 0, 0))
	local direction = VecDir(playerPos, forwardPos)
	
	local hit, hitPoint, distance, normal = raycast(cameraTransform.pos, direction)
	
	if hit then
		renderReticle(hitPoint, normal)
	end
	
	if InputPressed("usetool") and hit then
		local newGroup = createStormCloudGroupAbove(hitPoint)
		
		stormClouds[stormCloudIndex] = newGroup
		
		justPlacedTimer = justPlacedTimerMax
		
		stormCloudIndex = (stormCloudIndex % stormCloudsMaxIndex) + 1
	end
end

function draw(dt)	
	--menu_draw(dt)

	drawUI(dt)
	
	for i = 1, strikesToUiSound do
		local soundId = rumbleSoundsIndex
		local soundPath = "snd/rumble0" .. soundId .. ".ogg"
		
		rumbleSoundsIndex = (rumbleSoundsIndex % rumbleSounds) + 1
		
		UiSound(soundPath, 2)
	end
	
	strikesToUiSound = 0
	
	if GetString("game.player.tool") ~= "weathermachine" then
		return
	end
	
	if InputPressed("usetool") and justPlacedTimer > 0 then
		UiSound(announcer_storm_created_sfx, 3)
	end
	
	local justPlacedCirclePos = UiWorldToPixel(justPlacedPos)
end

-- UI Functions (excludes sound specific functions)

function drawUI(dt)
	
end

-- Creation Functions

function createStormCloudGroupAbove(pos)
	local newCloudGroup = deepcopy(stormCloudGroupClass)
	
	newCloudGroup.pos = VecAdd(pos, Vec(0, stormCloudHeight, 0))
	
	return newCloudGroup
end

function createCloud()
	local newCloud = deepcopy(cloudClass)
	
	return newCloud
end

function generateStrikeOffsets(cloud, endPos)
	if endPos == nil then
		return
	end

	local distance = VecDist(startPos, endPos)
	
	local points = math.ceil(distance / 2)
	
	for i = 1, points - 1 do
		local newOffset = rndVec(1.5)
		
		newOffset[2] = (i + 1) * -2
		
		local currStrikeOffset = VecAdd(newOffset, cloud.pos)
		local extraLength = math.random(0, 1)
		
		cloud.strikeOffsets[i] = {currStrikeOffset, extraLength}
	end
	
	cloud.strikeOffsets[points] = {endPos, 0}
end

-- Object handlers

function handleAllStormCloudGroups(dt)
	for i = 1, #stormClouds do
		local currentStormCloud = stormClouds[i]
		
		if currentStormCloud.lifetime > 0 or currentStormCloud.activeClouds > 0 then
			currentStormCloud.lifetime = currentStormCloud.lifetime - dt
			handleAllClouds(dt, currentStormCloud)
			
			currentStormCloud.spawnTimer = currentStormCloud.spawnTimer + dt
			
			if currentStormCloud.spawnTimer > currentStormCloud.spawnTimerMax and currentStormCloud.cloudSpawnCount > 0 then
				currentStormCloud.spawnTimer = 0
				currentStormCloud.cloudSpawnCount = currentStormCloud.cloudSpawnCount - 1
				currentStormCloud.activeClouds = currentStormCloud.activeClouds + 1
				
				local newCloud = createCloud() 
				
				local newCloudLocalPos = rndVec(currentStormCloud.cloudRange)
				
				if math.random(1, 10) > 5 then
					newCloudLocalPos[1] = newCloudLocalPos[1] / 2
					newCloudLocalPos[3] = newCloudLocalPos[3] / 2
				end
				
				newCloudLocalPos[2] = math.random(-15, 15) / 10
				
				newCloud.pos = VecAdd(newCloudLocalPos, currentStormCloud.pos)
				
				currentStormCloud.clouds[#currentStormCloud.clouds + 1] = newCloud
			end
		end
	end
end

function handleAllClouds(dt, stormCloudGroup)
	setupCloudParticle()
	
	for i = #stormCloudGroup.clouds, 1, -1 do
		local currentCloud = stormCloudGroup.clouds[i]
		
		if currentCloud ~= nil then
			if currentCloud.lifetime > 0 then
				currentCloud.lifetime = currentCloud.lifetime - dt
				spawnCloudParticles(currentCloud)
			end
			
			if currentCloud.lifetime < 0 and not currentCloud.struck then
				currentCloud.struck = true
				currentCloud.lifetime = currentCloud.strikeLifetime
				local hitPoint = strikeFromCloud(currentCloud, i)
				generateStrikeOffsets(currentCloud, hitPoint)
			elseif currentCloud.lifetime > 0 and currentCloud.struck then
				renderStrike(currentCloud)
			elseif currentCloud.lifetime <= 0 and currentCloud.struck and currentCloud.active then
				currentCloud.active = false
				stormCloudGroup.activeClouds = stormCloudGroup.activeClouds - 1
			end
		end
	end
end

-- World Sound functions

-- Action functions

function setupCloudParticle()
	ParticleReset()
	ParticleType("smoke")
	ParticleRadius(1)
end

function strikeFromCloud(cloud, cloudId)
	local cloudPos = cloud.pos
	local strikeDir = Vec(0, -1, 0)
	
	local hit, hitPoint = raycast(cloudPos, strikeDir)
	
	--local soundHandle = rumbleSounds[math.random(1, #rumbleSounds)]
	
	--PlaySound(cloud.pos, soundHandle, 50)
	if cloudId % 2 == 0 then
		strikesToUiSound = strikesToUiSound + 1
	end
	
	if hit then
		Explosion(hitPoint, cloud.strikePower)
		MakeHole(hitPoint, cloud.strikePower, cloud.strikePower * 0.75, cloud.strikePower * 0.5)
		return hitPoint
	end
	
	return nil
end

function spawnCloudParticles(cloud)
	local cloudLifetime = cloud.lifetime
	
	for i = 1, math.ceil(cloudClass.lifetime - cloudLifetime) do
		local offset = rndVec(2)
		
		offset[1] = offset[2] * 2
		offset[2] = math.abs(offset[2] / 2)
		
		SpawnParticle(VecAdd(cloud.pos, offset), Vec(0, 0, 0), 5)
	end
end

-- Sprite functions

function renderReticle(pos, normal)
	local spritePos = VecAdd(pos, VecScale(normal, 0.1))
	local spriteRot = nil
	
	if rtsCameraActive then
		spriteRot = QuatLookAt(pos, VecAdd(pos, Vec(0, 1, 0)))
	else
		spriteRot = QuatLookAt(pos, VecAdd(pos, normal))
	end
	
	local spriteTransform = Transform(spritePos, spriteRot)
	
	if rtsCameraActive then
		for i = 1, rtsCameraCircleCount do
			local circleSize = rtsCameraCircleMaxSize / rtsCameraCircleCount * i
			DrawSprite(circleSprite, spriteTransform, circleSize, circleSize, 0.5, 0, 0, 0.5, false, false)
		end
	else
		DrawSprite(circleSprite, spriteTransform, 2.5, 2.5, 0.5, 0, 0, 0.5, false, false)
		DrawSprite(circleSprite, spriteTransform, 2.5, 2.5, 1, 0, 0, 0.5, true, false)
	end
end

function renderStrike(cloud)
	if #cloud.strikeOffsets == 0 then
		return
	end
	
	for i = 1, #cloud.strikeOffsets do
		local prevPoint = nil
		local currStrike = cloud.strikeOffsets[i]
		local currPoint = currStrike[1]
		local currOffset = currStrike[2]
		
		if i == 1 then
			prevPoint = cloud.pos
		else
			prevPoint = cloud.strikeOffsets[i - 1][1]
		end
		
		local dirToCurr = VecDir(prevPoint, currPoint)
		
		local extraLength = VecScale(dirToCurr, currOffset)
		
		DrawLine(prevPoint, VecAdd(extraLength, currPoint), 0.8, 0.8, 1, cloud.lifetime / 2 / cloudClass.lifetime)
	end
end

-- UI Sound Functions
