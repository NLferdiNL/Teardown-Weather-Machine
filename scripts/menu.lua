#include "datascripts/inputList.lua"
#include "datascripts/color4.lua"
#include "scripts/ui.lua"
#include "scripts/textbox.lua"
#include "scripts/utils.lua"

local modName = "Weather Machine"

binds = {
	Open_Menu = "m",
}

local bindBackup = deepcopy(binds)

local bindOrder = {
	"Open_Menu", 
}
		
local bindNames = {
	Open_Menu = "Open Menu", 
}

local menuOpened = false
local rebinding = nil

local erasingBinds = 0

local menuWidth = 0.25
local menuHeight = 0.6

function menu_init()
	
end

function menu_tick(dt)
	if InputPressed(binds["Open_Menu"]) then
		menuOpened = not menuOpened
		
		if not menuOpened then
			menuCloseActions()
		end
	end
	
	if rebinding ~= nil then
		local lastKeyPressed = getKeyPressed()
		
		if lastKeyPressed ~= nil then
			binds[rebinding] = lastKeyPressed
			rebinding = nil
		end
	end
	
	textboxClass_tick()
	
	if erasingBinds > 0 then
		erasingBinds = erasingBinds - dt
	end
end

function menu_draw(dt)
	if not isMenuOpen() then
		return
	end
	
	UiMakeInteractive()
	
	UiPush()
		if not changelogActive then
			UiBlur(0.75)
		end
		
		UiAlign("center middle")
		UiTranslate(UiWidth() * 0.5, UiHeight() * 0.5)
		UiImageBox("ui/hud/infobox.png", UiWidth() * menuWidth, UiHeight() * menuHeight, 10, 10)
		
		UiWordWrap(UiWidth() * menuWidth)
		
		UiTranslate(0, -UiHeight() * menuWidth)
		
		UiFont("bold.ttf", 48)
		
		UiTranslate(0, 10)
		
		UiText(modName .. " Settings")
		
		UiFont("regular.ttf", 26)
		
		UiPush()
			UiTranslate(-UiWidth() * (menuWidth / 2), 50)
			for i = 1, #bindOrder do
				local id = bindOrder[i]
				local key = binds[id]
				drawRebindable(id, key)
				UiTranslate(0, 50)
			end
		UiPop()
		
		UiTranslate(0, 50 * (#bindOrder + 1))
	
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		
			if erasingBinds > 0 then
				UiPush()
				c_UiColor(Color4.Red)
				if UiTextButton("Are you sure?" , 400, 40) then
					binds = deepcopy(bindBackup)
					erasingBinds = 0
				end
				UiPop()
			else
				if UiTextButton("Reset binds to defaults" , 400, 40) then
					erasingBinds = 5
				end
			end
			
			UiTranslate(0, 50)
			
			if UiTextButton("Close" , 400, 40) then
				menuOpened = false
				menuCloseActions()
			end
		UiPop()
	UiPop()
end

function drawRebindable(id, key)
	UiPush()
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	
		UiTranslate(UiWidth() * menuWidth / 1.5, 0)
	
		UiAlign("right middle")
		UiText(bindNames[id] .. "")
		
		UiTranslate(UiWidth() * menuWidth * 0.1, 0)
		
		UiAlign("left middle")
		
		if rebinding == id then
			c_UiColor(Color4.Green)
		else
			c_UiColor(Color4.Yellow)
		end
		
		if UiTextButton(key, 40, 40) then
			rebinding = id
		end
	UiPop()
end

function isMenuOpen()
	return menuOpened
end

function setMenuOpen(val)
	menuOpened = val
end

function menuCloseActions()
	rebinding = nil
	erasingBinds = 0
end