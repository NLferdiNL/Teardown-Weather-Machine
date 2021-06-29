moddataPrefix = "savegame.mod.weathermachine"

function saveFileInit()
	saveVersion = GetInt(moddataPrefix .. "Version")
	
	if saveVersion < 1 or saveVersion == nil then
		saveVersion = 1
		SetInt(moddataPrefix .. "Version", saveVersion)
	end
	
	if saveVersion < 2 then
		saveVersion = 2
		SetInt(moddataPrefix .. "Version", saveVersion)
		
		changelogActive = true
	end
end