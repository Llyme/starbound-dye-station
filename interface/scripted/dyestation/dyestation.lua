require "/scripts/augments/item.lua"

local floor, min, max =
	math.floor, math.min, math.max
local format = string.format
local input
local buttonToggle

function footer(v)
	widget.setText("footer", v or buttonToggle and "Press button to remove dye." or "200 Pixels; 1 Empty Bottle")
end

function init()
	-- RGBA
	self.red = 0
	self.green = 0
	self.blue = 0
	self.alpha = 255
	-- HSV
	self.hue = 0
	self.sat = 0
	self.val = 0
	-- Hex
	self.hex = "000000"

	-- Init
	widget.setFontColor("preview", "#000000")
	footer()
end

function toHSV()
	local r, g, b = self.red/255, self.green/255, self.blue/255
	local v0, v1 = max(r, g, b), min(r, g, b)

	if v0 == v1 then
		return 0, 0, floor(v0*100)
	end

	local s = 1 - v1/v0

	return
		-- Hue
		floor(v0 == r and
			-- Red
			((v1 == g) and
			(360 - (b - v1)/s*60)%360 or
			((g - v1)/s*60)) or
		v0 == g and
			-- Green
			((v1 == b) and
			(120 - (r - v1)/s*60) or
			(120 + (b - v1)/s*60)) or
			-- Blue
			((v1 == r) and
			(240 - (g - v1)/s*60) or
			(240 + (r - v1)/s*60))),
		-- Saturation
		floor(s*100),
		-- Value
		floor(v0*100)
end

function toRGB()
	local h, s, v = self.hue, self.sat/100, self.val/100

	if s == 0 then
		v = floor(v*255)

		return v, v, v
	else v = v*255
		s = 1 - s

		local r =
			(h <= 60 or h >= 300) and 1 or
			(h < 120) and (2 - h/60) or
			(h > 240) and (h/60 - 4) or 0

		local g =
			(h >= 60 and h <= 180) and 1 or
			(h < 60) and (h/60) or
			(h < 240) and (4 - h/60) or 0

		local b =
			(h >= 180 and h <= 300) and 1 or
			(h > 300) and (6 - h/60) or
			(h > 120) and (h/60 - 2) or 0

		return
			floor(((1-r)*s + r)*v),
			floor(((1-g)*s + g)*v),
			floor(((1-b)*s + b)*v)
	end
end

function getHex(r,g,b,a)
	r,g,b = floor(self.red*(r or 1)),
			floor(self.green*(g or 1)),
			floor(self.blue*(b or 1))
	return format("%02X",r)..format("%02X",g)..format("%02X",b)..(a and format("%02X",self.alpha) or "")
end

function clamp(v, n)
	n = min(max(0,tonumber(widget.getText(v.."Value")) or 0),n)
	widget.setText(v.."Value", tostring(n))

	if self[v] ~= n then
		self[v] = n

		return true
	end
end

function clamp_rgb(v)
	if not input then
		input = true

		if clamp(v, 255) then
			self.hue, self.sat, self.val = toHSV()

			widget.setText(
				"hexValue",
				getHex(nil, nil, nil, true)
			)

			for _,v in pairs({"hue", "sat", "val"}) do
				widget.setText(v.."Value", tostring(self[v]))
			end

			footer()
		end

		input = nil
	end
end

function clamp_hsv(v, n)
	if not input then
		input = true

		if clamp(v, n) then
			self.red, self.green, self.blue = toRGB()

			widget.setText("hexValue",
				getHex(nil, nil, nil, true)
			)

			for _,v in pairs({"red", "green", "blue"}) do
				widget.setText(v.."Value",
					tostring(self[v])
				)
			end

			footer()
		end

		input = nil
	end
end

function redValue()
	clamp_rgb("red")
end

function greenValue()
	clamp_rgb("green")
end

function blueValue()
	clamp_rgb("blue")
end

function alphaValue()
	if not input then
		input = true

		if clamp("alpha", 255) then
			widget.setText(
				"hexValue",
				getHex(nil, nil, nil, true)
			)
			footer()
		end

		input = nil
	end
end

function hueValue()
	clamp_hsv("hue", 360)
	dyeBlock()
end

function satValue()
	clamp_hsv("sat", 100)
end

function valValue()
	clamp_hsv("val", 100)
end

function hexValue()
	if not input then
		local v = widget.getText("hexValue")

		if v:len() >= 6 then
			input = true

			local r, g, b, a =
				tonumber(v:sub(0, 2), 16),
				tonumber(v:sub(3, 4), 16),
				tonumber(v:sub(5, 6), 16),
				tonumber(v:sub(7, 8), 16)

			if r and g and b then
				self.red, self.green, self.blue = r, g, b
				self.alpha = a or 255
				self.hue, self.sat, self.val = toHSV()

				for _,v in pairs({"red", "green", "blue", "alpha", "hue", "sat", "val"}) do
					widget.setText(v.."Value",
						tostring(self[v])
					)
				end
			end

			input = nil
		end
	end

	widget.setFontColor("preview", "#"..getHex())
end

function dyeBlock()
	local id = pane.containerEntityId()
	local item = world.containerItemAt(id, 0)
	local hue = self.hue%360

	if item then
		item = Item.new(item)

		if item.config.materialId ~= nil then
			if item.parameters and item.parameters.materialHueShift ~= hue then
				world.containerConsumeAt(id, 0, item.count)

				item.parameters.materialHueShift = hue

				world.sendEntityMessage(id, "PutItemsAt", item, 0)
			end

			if not buttonToggle then
				buttonToggle = true

				widget.setButtonImages("dispense", {
					base = "/interface/scripted/dyestation/button_clear.png",
					hover = "/interface/scripted/dyestation/buttonhover_clear.png",
					press = "/interface/scripted/dyestation/buttonhover_clear.png"
				})
			end
		end

		return
	end

	if buttonToggle then
		buttonToggle = nil

		widget.setButtonImages("dispense", {
			base = "/interface/scripted/dyestation/button.png",
			hover = "/interface/scripted/dyestation/buttonhover.png",
			press = "/interface/scripted/dyestation/buttonhover.png"
		})
	end
end

function dispense()
	local id = pane.containerEntityId()
	local item = world.containerItemAt(id, 0)

	if item then
		if Item.new(item).config.materialId ~= nil then
			world.containerConsumeAt(id, 0, item.count)

			item.parameters.materialHueShift = nil

			player.giveItem(item)

			if buttonToggle then
				buttonToggle = nil

				widget.setButtonImages("dispense", {
					base = "/interface/scripted/dyestation/button.png",
					hover = "/interface/scripted/dyestation/buttonhover.png",
					press = "/interface/scripted/dyestation/buttonhover.png"
				})
			end
		elseif item.name == "bottle" then
			local cost = 200*item.count

			if player.currency("money") >= cost then
				player.consumeCurrency("money", cost)
				world.containerConsumeAt(id, 0, item.count)
				player.giveItem({
					name = "superdye",
					count = item.count,
					parameters = {
						shortdescription = getHex(nil, nil, nil, true).." Dye",
						dyecode = getHex(nil, nil, nil, true),
						inventoryIcon = "superdye.png?replace;ffffff="..
							getHex(1,1,1,true)..";dfdfdf="..
							getHex(0.87,0.87,0.87,true)..";9b9b9b="..
							getHex(0.61,0.61,0.61,true)
					}
				});
			else footer(cost.." pixels required.")
			end
		else footer("'Empty Bottle' or 'Block' required.")
		end
	else footer("'Empty Bottle' or 'Block' required.")
	end
end