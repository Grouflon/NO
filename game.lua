poke(0x5f2d, 1) -- enable mouse

--constants
skin_color={4,15}
clothes_color={2,3,8,10,11,12,14}
talk_anim={2,2,3,2,6,2,3,2,6,2,0,4,5,7,5,7,5,7,0,0}

agent_count=2
wait_range={1*60,4*60}
wander_speed=0.2
order_speed=0.3

--variables
agents={}
actions={}
pins={}

m_pos=vec2()
m_pressed={false,false}
m_released={false,false}
m_down={false,false}

hovered=nil
selected=nil

--ACTION
function action_create(_function,_agents,_p0,_p1,_p2,_p3)
	local _act={
		co=cocreate(_function),
		agents=_agents or {},
		args={_p0,_p1,_p2,_p3},
		alive=true,
		stop_f=nil,
	}
	foreach(_agents,function(_a)
		add(_a.actions,_act)
	end)
	add(actions,_act)
	return _act
end

function action_isalive(_act)
	if (not _act) return false
	if (not _act.alive) return false
	if (costatus(_act.co) == "dead") return false
	return true
end

function action_update(_act)
	if (not _act) return
	coresume(_act.co,_act,_act.args[1],_act.args[2],_act.args[3],_act.args[4])
	if (action_isalive(_act)) return

	action_stop(_act)
end

function action_stop(_act)
	if (not _act) return
	if (_act.stop_f) _act.stop_f(_act)
	foreach(_act.agents,function(_a) del(_a.actions,_act) end)
	del(actions,_act)
	_act.alive=false
end

--AGENT
function agent_goto(_a,_target,_speed)
	local _f=function(_act,_target,_speed)
		local _a=_act.agents[1]
		_speed=_speed or wander_speed
		_target=_target:copy()
		local _origin=_a.pos:copy()
		local _traj=_target-_a.pos
		local _timer=0
		local _time=0
		if (_speed>0) _time=_traj:len()/_speed
		local _t=0
		if (_time<=0) _t=1

		repeat
			_t=_timer/_time
			_a.pos=vec2_lerp(_origin,_target,_t)
			_timer+=1
			yield()
		until (_t>=1)
	end
	return action_create(_f,{_a},_target,_speed)
end

function agent_wait(_a,_time)
	local _f=function(_act,_time)
		local _timer=_time
		while(_timer>0) do
			_timer-=1
			yield()
		end
	end
	return action_create(_f,{_a},_time)
end

function agent_chat(_a1,_a2,_time)
	local _f=function(_act,_time)
		local _a1,a2=_act.agents[1], _act.agents[2]
		local _delta=_a2.pos-_a1.pos
		local _meet_pos=_a1.pos+_delta*0.5

		local _la,_ra=_a1,_a2
		if (_a2.pos.x<_a1.pos.x) then
			_la=_a2
			_ra=_a1
		end
		local _goto1=agent_goto(_la,_meet_pos-vec2(3,0),order_speed)
		local _goto2=agent_goto(_ra,_meet_pos+vec2(3,0),order_speed)
		while(action_isalive(_goto1) and action_isalive(_goto2)) do
			yield()
		end

		_act.pin=pin_create(_meet_pos.x,_meet_pos.y-3,1,talk_anim)
		local _wait1=agent_wait(_a1,_time)
		local _wait2=agent_wait(_a2,_time)
		while(action_isalive(_wait1) and action_isalive(_wait2)) do
			yield()
		end
	end

	local _act=action_create(_f,{_a1,_a2},_time)
	_act.stop_f=function(_act)
		if (_act.pin) pin_destroy(_act.pin)
	end
	return _act
end

function agent(_id,_pos)
	local _seed=rnd()
	srand(_seed)
 	local _a={
 		id=_id,
 		seed=_seed,
 		pos=_pos:copy(),
 		colors={
 			rnd(skin_color),
 			rnd(clothes_color)
 		},
 		actions={},
 		mode=0
 	}
	return _a
end

function agent_stop_actions(_a)
	for i=#_a.actions,1,-1 do
		action_stop(_a.actions[i])
	end
end

function agent_aabb(_a,_margin)
	_margin=_margin or 0
	return {
		_a.pos.x-_margin,
		_a.pos.y-1-_margin,
		_a.pos.x+1+_margin,
		_a.pos.y+_margin
	}
end

function agent_update(_a)
	if (#_a.actions==0) then
		if (_a.mode==0) then
			agent_wait(_a,rnd_range(wait_range[1],wait_range[2]))
		else
			agent_goto(_a,rnd_screenpos(30))
		end
		_a.mode=(_a.mode+1)%2
	end
end

function agent_draw(_a)
	pset(_a.pos.x,_a.pos.y,_a.colors[2])
	pset(_a.pos.x,_a.pos.y-1,_a.colors[1])
	pset(_a.pos.x+1,_a.pos.y,1)
end

-- UI
function panel_draw(_a, _y)
	local _base_y=128-_y
	rectfill(0,_base_y,128,128,1)

	gauge_draw(30,_base_y+8,30,0.7,"hunger",11,3)
	gauge_draw(30,_base_y+19,30,0.7,"sleep",11,3)
	gauge_draw(30,_base_y+30,30,0.7,"social",11,3)
end

function gauge_draw(_x,_y,_w,_value,_name,_c1,_c2)
	local _fill_w=_w*clamp01(_value)
	rectfill(_x,_y,_x+_w,_y+2,_c2)
	rectfill(_x+_w-_fill_w,_y,_x+_w,_y+2,_c1)
	print(_name,_x,_y-6,7)
end

function pin_create(_x,_y,_c,_anim)
	local _p={
		pos=vec2(_x,_y),
		col=_c,
		anim=_anim,
		anim_i=0,
		anim_t=0,
	}
	add(pins,_p)
	return _p
end

function pin_destroy(_p)
	del(pins, _p)
end

function pin_draw(_p)
	local _x,_y=_p.pos.x,_p.pos.y
	local _c=_p.col
	local _circy=_y-6
	local _r=4
	circfill(_x,_circy,_r,_c)
	spr(_p.anim[_p.anim_i+1],_x-2,_circy-2)
	--line(_x-2,_y-3,_x+2,_y-3,_c)
	line(_x-2,_y-2,_x+2,_y-2,_c)
	line(_x-1,_y-1,_x+1,_y-1,_c)
	pset(_x,_y,_c)

	_p.anim_t+=1
	if (_p.anim_t==9) then
		_p.anim_t=0
		_p.anim_i=(_p.anim_i+1)%#_p.anim
	end
end

-- SYSTEM
function _init()
	printh("-----INIT-----")
	for i=1,agent_count do
 	local _a=agent(i,rnd_screenpos(30))
 	add(agents,_a)
 end
end

function _update60()
	--mouse
	m_pos:set(stat(32),stat(33))
	local _prev_m_down={m_down[1],m_down[2]}
	m_down[1]=(stat(34)&1)>0
	m_down[2]=(stat(34)&2)>0
	m_pressed[1]=not _prev_m_down[1] and m_down[1]
	m_pressed[2]=not _prev_m_down[2] and m_down[2]
	m_released[1]=_prev_m_down[1] and not m_down[1]
	m_released[2]=_prev_m_down[2] and not m_down[2]

	--selection
	hovered=nil
	local _s_aabb={
	m_pos.x,
	 	m_pos.y,
		m_pos.x+1,
		m_pos.y+1
	}
	local _selectable={}
	for i=1,#agents do
		
		local _a=agents[i]
		local _a_aabb=agent_aabb(_a,4)
		
		if collision.aabb_aabb(
			_s_aabb,
			_a_aabb
		) then
			add(_selectable,_a)
		end
	end

	local _sqr_distance=999999
	foreach(_selectable, function(_a)
		local _d=(m_pos-_a.pos):sqr_len()
		if (_d<_sqr_distance) then
			_sqr_distance=_d
			hovered=_a
		end
	end)
	if (m_pressed[1]) selected=hovered

	-- orders
	if (selected and m_pressed[2]) then
		agent_stop_actions(selected)
		agent_goto(selected,m_pos,order_speed)
		selected.mode=0
		sfx(0)
	end
	if (btn(4)) then
		agent_stop_actions(agents[1])
		agent_stop_actions(agents[2])
		agent_chat(agents[1], agents[2],4*60)
	end

	-- actions
	for i=#actions,1,-1 do
		action_update(actions[i])
	end
 	
	-- agents
	foreach(agents,agent_update)
end

function _draw()
	local _bg_color=5
	cls(_bg_color)
	
	if hovered and hovered~=selected then
		local _x,_y=hovered.pos.x,hovered.pos.y
		local _c=6
		pset(_x,  _y-3,_c)
		pset(_x-2,_y-3,_c)
		pset(_x+2,_y-3,_c)
		pset(_x  ,_y+3,_c)
		pset(_x-2,_y+3,_c)
		pset(_x+2,_y+3,_c)
		pset(_x-4,_y-1,_c)
		pset(_x-4,_y+1,_c)
		pset(_x+4,_y-1,_c)
		pset(_x+4,_y+1,_c)
	end

	if selected then
		local _hw=4
		local _hh=3
		color(6)
		if (hovered) color(7)
		oval(
			selected.pos.x-_hw,
			selected.pos.y-_hh,
			selected.pos.x+_hw,
			selected.pos.y+_hh
		)
	end
	
	-- agents
	foreach(agents, agent_draw)

	-- pins
	foreach(pins, pin_draw)

	-- panel
	if (selected) panel_draw(selected, 35)
	
	-- cursor
	spr(1,m_pos.x-1,m_pos.y)
	
	draw_log()
end
