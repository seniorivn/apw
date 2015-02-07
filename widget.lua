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

-- Configuration variables
local width         = 10        -- width in pixels of progressbar
local margin_right  = 0         -- right margin in pixels of progressbar 
local margin_left   = 0         -- left margin in pixels of progressbar 
local margin_top    = 1         -- top margin in pixels of progressbar 
local margin_bottom = 5         -- bottom margin in pixels of progressbar  
local step          = 0.05      -- stepsize for volume change (ranges from 0 to 1)
local minstep	    = 0.01	-- minimum stepsize for volume
local color         = '#1a4b5c'--'#698f1e' -- foreground color of progessbar
local color_bg      = '#0F1419'--'#33450f' -- background color
local color_mute    = '#be2a15' -- foreground color when muted
local color_bg_mute = color_bg --'#532a15' -- background color when muted
local mixer         = 'pavucontrol' -- mixer command
local mixer_class   = 'Pavucontrol'
local veromix	    = 'veromix' --veromix command
local veromix_class = 'veromix'

-- End of configuration

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local pulseaudio = require("apw.pulseaudio")

local p = pulseaudio:Create()

local pulseBar = awful.widget.progressbar()
local pulseBox = wibox.widget.textbox(1)

pulseBar:set_width(width)
pulseBar:set_vertical(true)
pulseBar.step = step
pulseBar.minstep = minstep
    


local pulseWidget = wibox.layout.margin(pulseBar, margin_right, margin_left, margin_top, margin_bottom)

-- default colors overridden by Beautiful theme
color = beautiful.apw_fg_color or color
color_bg = beautiful.apw_bg_color or color_bg
color_mute = beautiful.apw_mute_fg_color or color_mute
color_bg_mute = beautiful.apw_mute_bg_color or color_bg_mute

function pulseWidget.setColor(mute)
	if mute then
		pulseBar:set_color(color_mute)
		pulseBar:set_background_color(color_bg_mute)
	else
		pulseBar:set_color(color)
		pulseBar:set_background_color(color_bg)
	end
end

local function _update()
	pulseBar:set_value(p.Volume)
	text= p.Perc 
	pulseBox:set_text(''..text..'')
	pulseWidget.setColor(p.Mute)
end

function pulseWidget.SetMixer(command)
	mixer = command
end

function pulseWidget.Up()
	p:SetVolume(p.Volume + pulseBar.step)
	_update()
end	

function pulseWidget.Down()
	p:SetVolume(p.Volume - pulseBar.step)
	_update()
end	

function pulseWidget.minUp()
	p:SetVolume(p.Volume + pulseBar.minstep)
	if p.Mute then
		pulseWidget.ToggleMute()
	end
	_update()
end	

function pulseWidget.minDown()
	p:SetVolume(p.Volume - pulseBar.minstep)
	if p.Mute then
		pulseWidget.ToggleMute()
	end
	_update()
end	


function pulseWidget.ToggleMute()
	p:ToggleMute()
	_update()
end

function pulseWidget.Update()
	p:UpdateState()
	 _update()
end

function pulseWidget.LaunchMixer()
	run_or_kill(mixer,  { class = mixer_class })
	_update()
end

function pulseWidget.LaunchVeromix()
	run_or_kill(veromix, { class = veromix_class })
	_update()	
end



function run_or_kill(cmd, properties)
   local clients = client.get()
   local focused = awful.client.next(0)
   local findex = 0
   local matched_clients = {}
   local n = 0
   for i, c in pairs(clients) do
      --make an array of matched clients
      if match(properties, c) then
         n = n + 1
         matched_clients[n] = c
         if c == focused then
            findex = n
         end
      end
   end
   if n > 0 then
      local c = matched_clients[1]
      -- if the focused window matched switch focus to next in list
      if 0 < findex and findex < n then
         c = matched_clients[findex+1]
      end
      local ctags = c:tags()
      if #ctags == 0 then
         -- ctags is empty, show client on current tag
         local curtag = awful.tag.selected()
         awful.client.movetotag(curtag, c)
      else
         -- Otherwise, pop to first tag client is visible on
         awful.tag.viewonly(ctags[1])
      end
      -- And then kill the client
      c:kill()
      return
   end
   awful.util.spawn(cmd)
end

-- Returns true if all pairs in table1 are present in table2
local function match (table1, table2)
   for k, v in pairs(table1) do
      if table2[k] ~= v and not table2[k]:find(v) then
         return false
      end
   end
   return true
end

function pulseWidget.getTextBox()
	return pulseBox
end


-- register mouse button actions
buttonsTable = awful.util.table.join(
		awful.button({ }, 1, pulseWidget.LaunchVeromix),
		awful.button({ }, 12, pulseWidget.ToggleMute),
		awful.button({ }, 2, pulseWidget.ToggleMute),
		awful.button({ }, 3, pulseWidget.LaunchMixer),
		awful.button({ }, 4, pulseWidget.minUp),
		awful.button({ }, 5, pulseWidget.minDown)
	)
pulseWidget:buttons(buttonsTable)
pulseBox:buttons(buttonsTable)


-- initialize
_update()

return pulseWidget
