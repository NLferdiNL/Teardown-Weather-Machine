local filteredKeys = { esc = "f", lmb = "f", mmb = "f", rmb = "f", space = "f", any = "f", m = "f" }

function isFilteredKey(key)
	return filteredKeys[key] ~= nil
end

function getKeyPressed()
	local pressedKey = InputLastPressedKey():lower()
	
	if pressedKey == nil or pressedKey == "" then
		return nil
	end
	
	if isFilteredKey(pressedKey) then
		return nil
	end
	
	return pressedKey
end