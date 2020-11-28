pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
last_time = 0
ellapsed = 0

mu_k = 0.1
vel = 3
score = 0

car = {
 x = 0,
 y = 50,
 w = 8,
 h = 8,
 col = 9,
 frame = 1,
 spr_index = 1,
}

sections = {
 {width = 10, score = 100, colour = 11 },
 {width = 20, score = 60 , colour = 3 },
 {width = 40, score = 20 , colour = 5 }
}

CHAR_H = 6
CHAR_W = 4

LBL_COL = 6

LEFT = 0
RIGHT = 1
UP = 2
DOWN = 3

PLY = 0
opt = 1

function str_width(str)
 return 
end

function rand(a, b)
 if a > b then
  local t = a
  a = b
  b = a
 end
 return a + (b - a) * rnd()
end

function _update()
 local t = time()
 dt = t - last_time
 ellapsed += dt
 last_time = t
 if btnp(UP, PLY) then
  opt = min(1, opt - 1)
 elseif btnp(DOWN, PLY) then
  opt = max(2, opt + 1)
 elseif btnp(pLEFT, PLY) then
  if opt == 1 then
   mu_k = max(0.01, mu_k - 0.01)
  elseif opt == 2 then
   vel = max(0.01, vel - 0.01)
  end
 elseif btnp(RIGHT, PLY) then
  if opt == 1 then
   mu_k += 0.01
  elseif opt == 2 then
   vel += 0.01
  end
 end

 car.frame = (car.frame + 1) % 100
 if car.frame % 5 then
  car.spr_index += 1
 end

end

function draw_spinner(label, val, x, y, selected)
 color(LBL_COL)
 print(label, x, y)
 local l = #label + 3 -- 1 space + 2 for the <- arrow
 local v = ' '..val..' '
 print(v, l * CHAR_W, y)
 color(selected and 10 or 5)
 local lv = #v
 print('⬅️ ', (#label + 1) * CHAR_W, y)
 print('➡️ ', (l + lv) * CHAR_W, y)
end

function draw_score(score)
 print(0, 2 * (CHAR_H + 1), 'score: '..score, LBL_COL)
 print(0, 3 * (CHAR_H + 1), 'press  to fire')
end

function draw_floor(car, sections)
 local floor_width = 128
 local floor_y = car.y + car.h
 line(0, floor_y, floor_width, floor_y, 6)
 local sections_x = 0
 for i = 1, #sections do
  sections_x += sections[i].width
 end
 
 for i = 1, #sections do
  local sec = sections[i]
  local w = sec.width
  line(sections_x, floor_y, w, floor_y, sec.colour)
  sections_x += w
 end

end

function _draw()
SPN_SEL = 7
SPN_UNSEL = 8
 cls()
 draw_spinner('friction coef:', mu_k, 1, 1, opt == 1)
 draw_spinner('vel:', vel, 1, CHAR_H + 1, opt == 2)
 draw_score(score)
 draw_floor(sections)

 spr(box.x, box.y)
end

function _init()
 last_time = time()
 -- shuffle sections, Fisher-Yates alg
 for i = #sections, 2 do
  local j = rand(i, 1)
  local tmp = sections[i]
  sections[i] = sections[j]
  sections[j] = tmp
 end
end

__gfx__
00000000099999900000000009999990000000000999999000000000099999900000000000000000000000000000000000000000000000000000000000000000
09999990090900900999999009090090099999900909009009999990090900900000000000000000000000000000000000000000000000000000000000000000
09090090090900900909009009090090090900900909009009090090090900900000000000000000000000000000000000000000000000000000000000000000
09090090999999990909009099999999090900909999999909090090999999990000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000
99999999900990099999999990099009999999999009900999999999900990090000000000000000000000000000000000000000000000000000000000000000
9d599d590d500d509dd99dd90dd00dd09dd99dd90dd00dd095d995d905d005d00000000000000000000000000000000000000000000000000000000000000000
0dd00dd00dd00dd00d500d500d500d5005d005d005d005d00dd00dd00dd00dd00000000000000000000000000000000000000000000000000000000000000000
