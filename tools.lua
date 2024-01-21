-- log
__log={}
function log(_str)
	add(__log,_str)
end
function draw_log()
	color(7)
	cursor()
	foreach(__log, print)
	__log={}
end

-- math
function lerp(_a,_b,_t)
	return _a+(_b-_a)*_t
end
function clamp01(_v)
	return mid(_v,0,1)
end

-- collision
collision={
	aabb_aabb=function(_a,_b)
	return not(
		_a[1]>_b[3] or
		_a[3]<_b[1] or
		_a[2]>_b[4] or
		_a[4]<_b[2]
	)
	end
}

-- vec2
vec2_mt = {}
vec2_mt.__index = vec2_mt

function vec2_mt:set(_x, _y)
  self.x = _x
  self.y = _y
end

function vec2_mt:__add(_v)
  return vec2(self.x + _v.x, self.y + _v.y)
end

function vec2_mt:__sub(_v)
  return vec2(self.x - _v.x, self.y - _v.y)
end

function vec2_mt:__mul(_s)
  return vec2(self.x * _s, self.y * _s)
end

function vec2_mt:dot(_v)
  return self.x * _v.x + self.y * _v.y
end

function vec2_mt:sqr_len()
  return self.x * self.x + self.y * self.y
end

function vec2_mt:len()
  return sqrt(self:sqr_len())
end

function vec2_mt:normalized()
  local _len = self:len()
  if _len > 0.0 then
    return vec2(self.x / _len, self.y / _len)
  else
    return vec2()
  end
end

function vec2_mt:flr()
  return vec2(flr(self.x), flr(self.y))
end

function vec2_mt:is_zero(_threshold)
  _threshold = _threshold or 0.01
  return abs(self.x) <= _threshold and abs(self.y) <= _threshold
end

function vec2_mt:copy()
  return vec2(self.x, self.y)
end

function vec2_mt:__tostring()
  return "{"..self.x..","..self.y.."}"
end

function vec2_lerp(_a, _b, _t)
  return vec2(
    lerp(_a.x, _b.x, _t),
    lerp(_a.y, _b.y, _t)
  )
end

function vec2(_x, _y)
  local _v = {
    x = _x or 0,
    y = _y or 0
  }
  setmetatable(_v, vec2_mt)
  return _v
end

--random
function rnd_range(_min,_max)
	return _min+rnd(_max-_min)
end

function rnd_screenpos(_margin)
	return vec2(
		rnd_range(_margin,128-_margin),
		rnd_range(_margin,128-_margin)
	)
end
