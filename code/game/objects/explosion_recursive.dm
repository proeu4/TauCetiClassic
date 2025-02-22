/obj
	var/explosion_resistance

var/list/explosion_turfs = list()
var/explosion_in_progress = 0

/proc/explosion_rec(turf/epicenter, power)
	var/loopbreak = 0
	while(explosion_in_progress)
		if(loopbreak >= 15) return
		sleep(10)
		loopbreak++

	if(power <= 0) return
	epicenter = get_turf(epicenter)
	if(!epicenter) return

	for(var/obj/item/device/radio/beacon/explosion_watcher/W in explosion_watcher_list)
		if(get_dist(W, epicenter) < 10)
			W.react_explosion(epicenter, power)

	message_admins("Explosion with size ([power]) in area [epicenter.loc.name] ([epicenter.x],[epicenter.y],[epicenter.z] <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[epicenter.x];Y=[epicenter.y];Z=[epicenter.z]'>JMP</A>)")
	log_game("Explosion with size ([power]) in area [epicenter.loc.name] ")

	playsound(epicenter, 'sound/effects/explosionfar.ogg', VOL_EFFECTS_MASTER, null, null, round(power*2,1) )
	playsound(epicenter, pick(SOUNDIN_EXPLOSION), VOL_EFFECTS_MASTER, null, null, round(power,1) )

	explosion_in_progress = 1
	explosion_turfs = list()

	explosion_turfs[epicenter] = power

	//This steap handles the gathering of turfs which will be ex_act() -ed in the next step. It also ensures each turf gets the maximum possible amount of power dealt to it.
	for(var/direction in cardinal)
		var/turf/T = get_step(epicenter, direction)
		T.explosion_spread(power - epicenter.explosion_resistance, direction)
		CHECK_TICK

	//This step applies the ex_act effects for the explosion, as planned in the previous step.
	for(var/turf/T in explosion_turfs)
		if(explosion_turfs[T] <= 0) continue
		if(!T) continue

		//Wow severity looks confusing to calculate... Fret not, I didn't leave you with any additional instructions or help. (just kidding, see the line under the calculation)
		var/severity = 4 - round(max(min( 3, ((explosion_turfs[T] - T.explosion_resistance) / (max(3,(power/3)))) ) ,1), 1)								//sanity			effective power on tile				divided by either 3 or one third the total explosion power
								//															One third because there are three power levels and I
								//															want each one to take up a third of the crater
		var/x = T.x
		var/y = T.y
		var/z = T.z
		T.ex_act(severity)
		if(!T)
			T = locate(x,y,z)
		for(var/atom/A in T)
			A.ex_act(severity)
		CHECK_TICK

	explosion_in_progress = 0

/turf
	var/explosion_resistance

/turf/space
	explosion_resistance = 10

/turf/simulated/floor
	explosion_resistance = 1

/turf/simulated/mineral
	explosion_resistance = 2

/turf/simulated/shuttle/floor
	explosion_resistance = 1

/turf/simulated/shuttle/floor4
	explosion_resistance = 1

/turf/simulated/shuttle/plating
	explosion_resistance = 1

/turf/simulated/shuttle/wall
	explosion_resistance = 5

/turf/simulated/wall
	explosion_resistance = 5

/turf/simulated/wall/r_wall
	explosion_resistance = 25

//Code-wise, a safe value for power is something up to ~25 or ~30.. This does quite a bit of damage to the station.
//direction is the direction that the spread took to come to this tile. So it is pointing in the main blast direction - meaning where this tile should spread most of it's force.
/turf/proc/explosion_spread(power, direction)
	if(power <= 0)
		return

	/*
	sleep(2)
	new/obj/effect/debugging/marker(src)
	*/

	if(explosion_turfs[src] >= power)
		return //The turf already sustained and spread a power greated than what we are dealing with. No point spreading again.
	explosion_turfs[src] = power

	var/spread_power = power - src.explosion_resistance //This is the amount of power that will be spread to the tile in the direction of the blast
	var/side_spread_power = power - 2 * src.explosion_resistance //This is the amount of power that will be spread to the side tiles
	for(var/obj/O in src)
		if(O.explosion_resistance)
			spread_power -= O.explosion_resistance
			side_spread_power -= O.explosion_resistance
		CHECK_TICK

	var/turf/T = get_step(src, direction)
	T.explosion_spread(spread_power, direction)
	T = get_step(src, turn(direction,90))
	T.explosion_spread(side_spread_power, turn(direction,90))
	T = get_step(src, turn(direction,-90))
	T.explosion_spread(side_spread_power, turn(direction,90))

	/*
	for(var/direction in cardinal)
		var/turf/T = get_step(src, direction)
		T.explosion_spread(spread_power)
	*/

/turf/unsimulated/explosion_spread(power)
	return //So it doesn't get to the parent proc, which simulates explosions
