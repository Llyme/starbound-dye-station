require "/scripts/util.lua"
require "/scripts/augments/item.lua"

function toHex(v)
	return string.format("%02x", math.min(math.floor(v),255))
end

function normalize(dyeable)
	local color = dyeable:instanceValue("colorOptions",{})[1]
	local out = {}
	local m = 0

	if color then
		if type(color) ~= "string" then
			for k,_ in pairs(color) do
				out[k] = tonumber(k:sub(0,2),16)+tonumber(k:sub(3,4),16)+tonumber(k:sub(5,6),16)
				if out[k] > m then
					m = out[k]
				end
			end
			for k,v in pairs(out) do
				if m > 0 then
					out[k] = v/m
		    else out[k] = 1
				end
			end
		end
	end

	return out
end

function colorize(alpha, color)
	local directive = "replace"

	for k,v in pairs(alpha) do
		directive = directive..";"..k.."="..toHex(v*tonumber(color:sub(0,2),16))..toHex(v*tonumber(color:sub(3,4),16))..toHex(v*tonumber(color:sub(5,6),16))
	end

	return directive
end

function paletteSwapDirective(color)
  local directive = "replace"
  for key,val in pairs(color) do
    directive = directive .. ";" .. key .. "=" .. val
  end
  return directive
end

function getColorOptions(dyeable)
  local options = {}
  for _,color in ipairs(dyeable:instanceValue("colorOptions", {})) do
    if type(color) == "string" then
      table.insert(options, color)
    else
      table.insert(options, paletteSwapDirective(color))
    end
  end
  return options
end

function getDirectives(dyeable)
  local directives = dyeable:instanceValue("directives", "")
  if directives == "" then
    local colorOptions = getColorOptions(dyeable)
    if #colorOptions > 0 then
      local colorIndex = dyeable:instanceValue("colorIndex", 0)
      directives = "?" .. util.tableWrap(colorOptions, colorIndex + 1)
    end
  end
  return directives
end

function isArmor(item)
  local armors = {
      headarmor = true,
      chestarmor = true,
      legsarmor = true,
      backarmor = true
    }
  return armors[item:type()] == true
end

function apply(input)
  local output = Item.new(input)

  if not isArmor(output) then
    return nil
  end

  local color = config.getParameter("dyecode")
  local currentDirectives = getDirectives(output)

  if color then
	local newDirectives = colorize(normalize(output),color).."?multiply=FFFFFF"..(color:sub(7,8) or "FF")
	if newDirectives ~= currentDirectives then
		output:setInstanceValue("directives", "?"..newDirectives)
		return output:descriptor(), 1
	end
  end
end
