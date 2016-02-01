-- Copyright 2013 mokasin
-- This file is part of the Awesome Pulseaudio Widget (APW).
-- 
-- APW is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- APW is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with APW. If not, see <http://www.gnu.org/licenses/>.

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local pulseaudio = require("apw.pulseaudio")

local pulsewidget = { mt = {} }
p = pulseaudio:Create()

function pulsewidget:setcolor(mute)
	if pulsewidget.progressbar then
		if mute then
			pulsewidget.progressbar:set_color(pulsewidget.color_mute)
			pulsewidget.progressbar:set_background_color(pulsewidget.color_bg_mute)
		else
			pulsewidget.progressbar:set_color(pulsewidget.color)
			pulsewidget.progressbar:set_background_color(pulsewidget.color_bg)
		end
	end
end

local function _update()
	if pulsewidget.progressbar then
		pulsewidget.progressbar:set_value(p.Volume)
	end
	text= p.Perc 
	if pulsewidget.textbox then
		print(text)
		pulsewidget.textbox:set_text(''..text..'')
	end
	pulsewidget:setcolor(p.Mute)
end

function pulsewidget.up()
	p:SetVolume(p.Volume + pulsewidget.step)
	_update()
end	

function pulsewidget.down()
	p:SetVolume(p.Volume - pulsewidget.step)
	_update()
end	

function pulsewidget.minup()
	p:SetVolume(p.Volume + pulsewidget.minstep)
	if p.Mute then
		pulsewidget.togglemute()
	end
	_update()
end	

function pulsewidget.mindown()
	p:SetVolume(p.Volume - pulsewidget.minstep)
	if p.Mute then
		pulsewidget.togglemute()
	end
	_update()
end	


function pulsewidget.togglemute()
	p:ToggleMute()
	_update()
end

function pulsewidget.update()
	p:UpdateState()
	 _update()
end
local notification = nil
function pulsewidget:hide()
	if notification ~= nil then
		naughty.destroy(notification)
		notification = nil
	end
end
function pulsewidget.text_grabber()
	--local f = io.popen("pacmd list-sinks") -- | grep -i 'index: 1' -A 50")
	local str = "pacmd list-sinks | grep -i ".."'volume: f'".." | awk '{printf $5 "..'"\\'..'n"'.."}'"
	--print(str)
	local volumes = io.popen(str)
	local names = io.popen("pacmd list-sinks | grep -i ".."'profile.name'".." | awk '{printf $3 "..'"\\'..'n"'.."}'")
	local mutes = io.popen("pacmd list-sinks | grep -i 'muted' ")
	local vol = {}
	local nm = {}
	local mu = {}
	for v in mutes:lines() do
		table.insert(mu, v)
	end
	for v in names:lines() do
		table.insert(nm, v)
	end
	for v in volumes:lines() do
		table.insert(vol, v)
	end
	volumes:close()
	names:close()
	mutes:close()
	local result = ""
	for i,k in pairs(vol) do
		result =result..nm[i].."       "..k..mu[i].."\n"
	end
	return result
end

function pulsewidget:show(t_out)
	pulsewidget:hide()

	notification = naughty.notify({
		preset = fs_notification_preset,
		text = pulsewidget.text_grabber(),
		timeout = t_out,
		screen = mouse.screen,
	})
end
function pulsewidget:attach(widget, args)
	local args = args or {}

	widget:connect_signal('mouse::enter', function () pulsewidget:show(0) end)
	widget:connect_signal('mouse::leave', function () pulsewidget:hide() end)
end

function pulsewidget:setbuttons(widget, args)
	local args 	= args	      or {}
	local mixer1 	= args.mixer1 or pulsewidget.mixer1
	local mixer2 	= args.mixer2 or pulsewidget.mixer2
	local mute 	= args.mute   or pulsewidget.togglemute
	local minu 	= args.minu   or pulsewidget.minup
	local mind 	= args.mind   or pulsewidget.mindown
	local table 	= args.table  or {}
	buttons = awful.util.table.join(
		awful.button({ }, 1,  mixer1),
		awful.button({ }, 12, mute),
		awful.button({ }, 2,  mute),
		awful.button({ }, 3,  mixer2),
		awful.button({ }, 4,  minu),
		awful.button({ }, 5,  mind)
	)

	for i,k in pairs(table) do
		awful.util.table.join(buttons, k)
	end
	widget:buttons(buttons)
end

-- initialize
local function new(args)

	-- Configuration variables
	pulsewidget.width         	= args.width or beautiful.apw_width or 10        			-- width in pixels of progressbar
	pulsewidget.margin_right  	= args.margin_right or beautiful.apw_margin_right or 0			-- right margin in pixels of progressbar 
	pulsewidget.margin_left   	= args.margin_left or beautiful.apw_margin_left or 0			-- left margin in pixels of progressbar 
	pulsewidget.margin_top    	= args.margin_top or beautiful.apw_margin_top or 1         		-- top margin in pixels of progressbar 
	pulsewidget.margin_bottom 	= args.margin_bottom or beautiful.apw_margin_bottom or 5         	-- bottom margin in pixels of progressbar  
	pulsewidget.step          	= args.step or 0.05      						-- stepsize for volume change (ranges from 0 to 1)
	pulsewidget.minstep		= args.minstep or 0.01							-- minimum stepsize for volume
	pulsewidget.color         	= args.color or beautiful.apw_fg_color or "#888888"  			--'#698f1e' -- foreground color of progessbar'#1a4b5c'
	pulsewidget.color_bg      	= args.color_bg or beautiful.apw_bg_color or "#343434" 			--'#33450f' -- background color'#0F1419'--
	pulsewidget.color_mute    	= args.color_mute or beautiful.apw_mute_fg_color or '#be2a15' 		-- foreground color when muted
	pulsewidget.color_bg_mute 	= args.color_bg_mute or beautiful.apw_mute_bg_color or pulsewidget.color_bg 	--'#532a15' -- background color when muted
	pulsewidget.mixer1	    	= args.mixer1 or function() os.execute('veromix') end			-- function to run on 1 button
	pulsewidget.mixer2       	= args.mixer2 or function() os.execute('pavucontrol') end		-- function to run on 3 button
	pulsewidget.textbox 		= args.textbox 
	pulsewidget.progressbar 	= args.progressbar 
	pulsewidget.progressbar_vert	= args.progressbar_vert or true
	pulsewidget.container		= args.container
	pulsewidget.table		= args.table or {}
	pulsewidget.text_grabber	= args.text_grabber or pulsewidget.text_grabber
	if pulsewidget.container == nil then
		pulsewidget.container = wibox.layout.fixed.horizontal()
	elseif pulsewidget.container == false then
		pulsewidget.container = nil
	elseif pulsewidget.container == true then
		pulsewidget.container = wibox.layout.fixed.horizontal()
	end
	if pulsewidget.textbox == nil then
		pulsewidget.textbox = wibox.widget.textbox("vol")
	elseif pulsewidget.textbox == false then
		pulsewidget.textbox = nil
	elseif pulsewidget.textbox == true then
		pulsewidget.textbox = wibox.widget.textbox("vol")
	end
	if pulsewidget.progressbar == nil then
		pulsewidget.progressbar = awful.widget.progressbar()
	elseif pulsewidget.progressbar == false then
		pulsewidget.progressbar = nil
	elseif pulsewidget.progressbar == true then
		pulsewidget.progressbar = awful.widget.progressbar()
	end

	-- End of configuration

	local function add(item, name)
		if pulsewidget.container then
			pulsewidget.container:add(item)
		else
			pulsewidget.table[name] = item
		end
	end

	if pulsewidget.progressbar then
		pulsewidget.progressbar:set_width(pulsewidget.width)
		pulsewidget.progressbar:set_vertical(pulsewidget.progressbar_vert)
		 
		add(wibox.layout.margin(pulsewidget.progressbar, pulsewidget.margin_right, pulsewidget.margin_left, pulsewidget.margin_top, pulsewidget.margin_bottom), "progressbar")
	end

	if pulsewidget.textbox then
		add(pulsewidget.textbox, "textbox")
	end
	pulsewidget.update()

	if pulsewidget.container then
		--pulsewidget.container:buttons(pulsewidget.buttons)
		return pulsewidget.container
	else
		--for i,k in pairs(pulsewidget.table) do
			--k:buttons(pulsewidget.buttons)
		--end
		return pulsewidget.table
	end

end

function pulsewidget.mt:__call(...)
    return new(...)
end

return setmetatable(pulsewidget, pulsewidget.mt)
