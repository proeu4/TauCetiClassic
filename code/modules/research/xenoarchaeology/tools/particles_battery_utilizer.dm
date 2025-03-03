
/*
/obj/item/weapon/anobattery
	name = "Anomaly power battery"
	icon = 'icons/obj/xenoarchaeology/machinery.dmi'
	icon_state = "anobattery0"
	var/datum/artifact_effect/battery_effect
	var/capacity = 300
	var/stored_charge = 0
	var/effect_id = ""

/obj/item/weapon/anobattery/atom_init()
	battery_effect = new()
	. = ..()

/obj/item/weapon/anobattery/update_icon()
	var/power_inside = (stored_charge/capacity) * 100
	power_inside = min(power_inside, 100)
	icon_state = "anobattery[round(power_inside, 25)]"

/obj/item/weapon/anobattery/proc/use_power(amount)
	stored_charge = max(0, stored_charge - amount)

/obj/item/weapon/anodevice
	name = "Anomaly power utilizer"
	icon = 'icons/obj/xenoarchaeology/machinery.dmi'
	icon_state = "anodev"
	var/activated = 0
	var/duration = 0
	var/duration_max = 300 // 30 sec max duration
	var/interval = 0
	var/interval_max = 100 // 10 sec max interval
	var/time_end = 0
	var/last_activation = 0
	var/last_process = 0
	var/obj/item/weapon/anobattery/inserted_battery
	var/turf/archived_loc
	var/energy_consumed_on_touch = 100

/obj/item/weapon/anodevice/atom_init()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/weapon/anodevice/attackby(obj/I, mob/user)
	if(istype(I, /obj/item/weapon/anobattery))
		if(!inserted_battery)
			to_chat(user, "<span class='notice'>You insert the battery.</span>")
			user.drop_item()
			I.loc = src
			inserted_battery = I
			update_icon()
	else
		return ..()

/obj/item/weapon/anodevice/attack_self(mob/user)
	return src.interact(user)

/obj/item/weapon/anodevice/interact(mob/user)
	var/dat = "<b>Anomalous Materials Energy Utiliser</b><br>"
	if(inserted_battery)
		if(activated)
			dat += "Device active.<br>"

		dat += "[inserted_battery] inserted, anomaly ID: [inserted_battery.battery_effect ? (inserted_battery.battery_effect.artifact_id == "" ? "???" : "[inserted_battery.battery_effect.artifact_id]") : "NA"]<BR>"
		dat += "<b>Charge:</b> [round(inserted_battery.stored_charge,1)] / [inserted_battery.capacity]<BR>"
		dat += "<b>Time left activated:</b> [round(max((time_end - last_process) / 10, 0))]<BR>"
		if(activated)
			dat += "<a href='?src=\ref[src];shutdown=1'>Shutdown</a><br>"
		else
			dat += "<A href='?src=\ref[src];startup=1'>Start</a><BR>"
		dat += "<BR>"

		dat += "<b>Activate duration (sec):</b> <A href='?src=\ref[src];changetime=-100;duration=1'>--</a> <A href='?src=\ref[src];changetime=-10;duration=1'>-</a> [duration/10] <A href='?src=\ref[src];changetime=10;duration=1'>+</a> <A href='?src=\ref[src];changetime=100;duration=1'>++</a><BR>"
		dat += "<b>Activate interval (sec):</b> <A href='?src=\ref[src];changetime=-100;interval=1'>--</a> <A href='?src=\ref[src];changetime=-10;interval=1'>-</a> [interval/10] <A href='?src=\ref[src];changetime=10;interval=1'>+</a> <A href='?src=\ref[src];changetime=100;interval=1'>++</a><BR>"
		dat += "<br>"
		dat += "<A href='?src=\ref[src];ejectbattery=1'>Eject battery</a><BR>"
	else
		dat += "Please insert battery<br>"

	dat += "<hr>"
	dat += "<a href='?src=\ref[src];refresh=1'>Refresh</a> <a href='?src=\ref[src];close=1'>Close</a>"

	var/datum/browser/popup = new(user, "anodevice", name, 450, 500)
	popup.set_content(dat)
	popup.open()

/obj/item/weapon/anodevice/process()
	if(activated)
		if(inserted_battery && inserted_battery.battery_effect && (inserted_battery.stored_charge > 0))
			// make sure the effect is active
			if(!inserted_battery.battery_effect.activated)
				inserted_battery.battery_effect.ToggleActivate(1)

			// update the effect loc
			var/turf/T = get_turf(src)
			if(T != archived_loc)
				archived_loc = T
				inserted_battery.battery_effect.UpdateMove()

			// if someone is holding the device, do the effect on them
			var/mob/holder
			if(ismob(src.loc))
				holder = src.loc

			// handle charge
			if(world.time - last_activation > interval)
				if(inserted_battery.battery_effect.effect == EFFECT_TOUCH)
					if(interval > 0)
						// apply the touch effect to the holder
						if(holder)
							to_chat(holder, "the [bicon(src)] [src] held by [holder] shudders in your grasp.")
						else
							src.loc.visible_message("the [bicon(src)] [src] shudders.")
						inserted_battery.battery_effect.DoEffectTouch(holder)

						// consume power
						inserted_battery.use_power(energy_consumed_on_touch)
					else
						// consume power equal to time passed
						inserted_battery.use_power(world.time - last_process)

				else if(inserted_battery.battery_effect.effect == EFFECT_PULSE)
					inserted_battery.battery_effect.chargelevel = inserted_battery.battery_effect.chargelevelmax

					// consume power relative to the time the artifact takes to charge and the effect range
					inserted_battery.use_power(inserted_battery.battery_effect.effectrange * inserted_battery.battery_effect.effectrange * inserted_battery.battery_effect.chargelevelmax)

				else
					// consume power equal to time passed
					inserted_battery.use_power(world.time - last_process)

				last_activation = world.time
				update_icon()

			// process the effect
			inserted_battery.battery_effect.process()

			// work out if we need to shutdown
			if(inserted_battery.stored_charge <= 0)
				src.loc.visible_message("<span class='notice'>[bicon(src)] [src] buzzes.</span>", "<span class='notice'>[bicon(src)] You hear something buzz.</span>")
				shutdown_emission()
			else if(world.time > time_end)
				src.loc.visible_message("<span class='notice'>[bicon(src)] [src] chimes.</span>", "<span class='notice'>[bicon(src)] You hear something chime.</span>")
				shutdown_emission()
		else
			src.visible_message("<span class='notice'>[bicon(src)] [src] buzzes.</span>", "<span class='notice'>[bicon(src)] You hear something buzz.</span>")
			shutdown_emission()
		last_process = world.time
		update_icon()

/obj/item/weapon/anodevice/proc/shutdown_emission()
	if(activated)
		activated = 0
		if(inserted_battery.battery_effect.activated)
			inserted_battery.battery_effect.ToggleActivate(1)
		updateDialog()

/obj/item/weapon/anodevice/Topic(href, href_list)

	if(href_list["changetime"])
		var/timedif = text2num(href_list["changetime"])
		if(href_list["duration"])
			duration += timedif
			//max 30 sec duration
			duration = min(max(duration, 0), duration_max)
			if(activated)
				time_end += timedif
		else if(href_list["interval"])
			interval += timedif
			// max 10 sec interval
			interval = min(max(interval, 0), interval_max)
	if(href_list["startup"])
		if(inserted_battery && inserted_battery.battery_effect && (inserted_battery.stored_charge > 0) )
			activated = 1
			src.visible_message("<span class='notice'>[bicon(src)] [src] whirrs.</span>", "<span class='notice'>[bicon(src)]You hear something whirr.</span>")
			if(!inserted_battery.battery_effect.activated)
				inserted_battery.battery_effect.ToggleActivate(1)
			time_end = world.time + duration
	if(href_list["shutdown"])
		activated = 0
	if(href_list["ejectbattery"])
		shutdown_emission()
		inserted_battery.loc = get_turf(src)
		inserted_battery = null
		update_icon()
	if(href_list["close"])
		usr << browse(null, "window=anodevice")
	else if(ismob(src.loc))
		var/mob/M = src.loc
		src.interact(M)
	..()

*/

/obj/item/weapon/particles_battery
	name = "Exotic particles power battery"
	icon = 'icons/obj/xenoarchaeology/machinery.dmi'
	icon_state = "particles_battery0"
	w_class = ITEM_SIZE_SMALL
	var/datum/artifact_effect/battery_effect
	var/capacity = 200
	var/stored_charge = 0
	var/effect_id = ""

/obj/item/weapon/particles_battery/atom_init()
	. = ..()
	battery_effect = new()

/obj/item/weapon/particles_battery/update_icon()
	var/power_stored = (stored_charge / capacity) * 100
	power_stored = min(power_stored, 100)
	icon_state = "particles_battery[round(power_stored, 25)]"

/obj/item/weapon/xenoarch_utilizer
	name = "Exotic particles power utilizer"
	icon = 'icons/obj/xenoarchaeology/machinery.dmi'
	icon_state = "utilizer"
	w_class = ITEM_SIZE_SMALL
	var/cooldown = 0
	var/activated = FALSE
	var/timing = FALSE
	var/time = 50
	var/archived_time = 50
	var/obj/item/weapon/particles_battery/inserted_battery
	var/turf/archived_loc
	var/cooldown_to_start = 0

/obj/item/weapon/xenoarch_utilizer/atom_init()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/weapon/xenoarch_utilizer/attackby(obj/I, mob/user)
	if(istype(I, /obj/item/weapon/particles_battery))
		if(!inserted_battery)
			if(user.drop_item(I, src))
				to_chat(user, "<span class='notice'>You insert the battery.</span>")
				playsound(src, 'sound/items/buttonswitch.ogg', VOL_EFFECTS_MASTER)
				inserted_battery = I
				update_icon()
	else
		return ..()

/obj/item/weapon/xenoarch_utilizer/attack_self(mob/user)
	if(in_range(src, user))
		return src.interact(user)

/obj/item/weapon/xenoarch_utilizer/interact(mob/user)

	var/dat = "<b>Exotic Particles Energy Utilizer</b><br>"
	if(inserted_battery)
		if(cooldown)
			dat += "Cooldown in progress, please wait.<br>"
		else if(activated)
			if(timing)
				dat += "Device active.<br>"
			else
				dat += "Device active in timed mode.<br>"

		dat += "[inserted_battery] inserted, exotic wave ID: [inserted_battery.battery_effect.artifact_id ? inserted_battery.battery_effect.artifact_id : "NA"]<BR>"
		dat += "<b>Total Power:</b> [round(inserted_battery.stored_charge, 1)]/[inserted_battery.capacity]<BR><BR>"
		dat += "<b>Timed activation:</b> <A href='?src=\ref[src];neg_changetime_max=-100'>--</a> <A href='?src=\ref[src];neg_changetime=-10'>-</a> [time >= 1000 ? "[time/10]" : time >= 100 ? " [time/10]" : "  [time/10]" ] <A href='?src=\ref[src];changetime=10'>+</a> <A href='?src=\ref[src];changetime_max=100'>++</a><BR>"
		if(cooldown)
			dat += "<font color=red>Cooldown in progress.</font><BR>"
			dat += "<br>"
		else if(!activated && world.time >= cooldown_to_start)
			dat += "<A href='?src=\ref[src];startup=1'>Start</a><BR>"
			dat += "<A href='?src=\ref[src];startup=1;starttimer=1'>Start in timed mode</a><BR>"
		else
			dat += "<a href='?src=\ref[src];shutdown=1'>Shutdown emission</a><br>"
			dat += "<br>"
		dat += "<A href='?src=\ref[src];ejectbattery=1'>Eject battery</a><BR>"
	else
		dat += "Please insert battery<br>"

		dat += "<br>"
		dat += "<br>"
		dat += "<br>"

		dat += "<br>"
		dat += "<br>"
		dat += "<br>"

	dat += "<hr>"
	dat += "<a href='?src=\ref[src]'>Refresh</a> <a href='?src=\ref[src];close=1'>Close</a>"

	var/datum/browser/popup = new(user, "utilizer", name, 400, 500)
	popup.set_content(dat)
	popup.open()

/obj/item/weapon/xenoarch_utilizer/process()
	update_icon()
	if(cooldown > 0)
		cooldown -= 1
		if(cooldown <= 0)
			cooldown = 0
			src.visible_message("<span class='notice'>[bicon(src)] [src] chimes.</span>", "<span class='notice'>[bicon(src)] You hear something chime.</span>")
	else if(activated)
		if(inserted_battery && inserted_battery.battery_effect)
			// make sure the effect is active
			if(!inserted_battery.battery_effect.activated)
				inserted_battery.battery_effect.ToggleActivate(1)

			// update the effect loc
			var/turf/T = get_turf(src)
			if(T != archived_loc)
				archived_loc = T
				inserted_battery.battery_effect.UpdateMove()

			// process the effect
			inserted_battery.battery_effect.process()
			// if someone is holding the device, do the effect on them
			if(inserted_battery.battery_effect.effect == EFFECT_TOUCH && ismob(src.loc))
				inserted_battery.battery_effect.DoEffectTouch(src.loc)

			// handle charge
			inserted_battery.stored_charge -= 1
			if(inserted_battery.stored_charge <= 0)
				shutdown_emission()

			// handle timed mode
			if(timing)
				time -= 1
				if(time <= 0)
					shutdown_emission()
		else
			shutdown()

/obj/item/weapon/xenoarch_utilizer/proc/shutdown_emission()
	if(activated)
		activated = FALSE
		timing = FALSE
		src.visible_message("<span class='notice'>[bicon(src)] [src] buzzes.</span>", "[bicon(src)]<span class='notice'>You hear something buzz.</span>")

		cooldown = archived_time / 2

		if(inserted_battery.battery_effect.activated)
			inserted_battery.battery_effect.ToggleActivate(1)
	updateDialog()

/obj/item/weapon/xenoarch_utilizer/Topic(href, href_list)

	if((get_dist(src, usr) > 1))
		return
	usr.set_machine(src)
	if(href_list["neg_changetime_max"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		time += -100
		if(time > inserted_battery.capacity)
			time = inserted_battery.capacity
		else if (time < 0)
			time = 0
	if(href_list["neg_changetime"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		time += -10
		if(time > inserted_battery.capacity)
			time = inserted_battery.capacity
		else if (time < 0)
			time = 0
	if(href_list["changetime"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		time += 10
		if(time > inserted_battery.capacity)
			time = inserted_battery.capacity
		else if (time < 0)
			time = 0
	if(href_list["changetime_max"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		time += 100
		if(time > inserted_battery.capacity)
			time = inserted_battery.capacity
		else if (time < 0)
			time = 0
	if(href_list["startup"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		activated = TRUE
		timing = FALSE
		cooldown_to_start = world.time + 10 // so we cant abuse the startup button
		update_icon()
		if(!inserted_battery.battery_effect.activated)
			message_admins("anomaly battery [inserted_battery.battery_effect.artifact_id]([inserted_battery.battery_effect]) emission started by [key_name(usr)]")
			inserted_battery.battery_effect.ToggleActivate(1)
	if(href_list["shutdown"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		activated = FALSE
	if(href_list["starttimer"])
		timing = TRUE
		archived_time = time
	if(href_list["ejectbattery"])
		playsound(src, 'sound/machines/click.ogg', VOL_EFFECTS_MASTER)
		shutdown_emission()
		inserted_battery.forceMove(get_turf(src))
		if(ishuman(usr))
			var/mob/living/carbon/human/H = usr
			H.put_in_hands(inserted_battery)
		inserted_battery.update_icon()
		inserted_battery = null
		update_icon()
	if(href_list["close"])
		usr << browse(null, "window=utilizer")
		usr.unset_machine(src)
		return
	src.interact(usr)
	..()
	updateDialog()
	update_icon()

/obj/item/weapon/xenoarch_utilizer/update_icon()
	if(!inserted_battery)
		icon_state = "utilizer"
		return
	var/is_emitting = "_off"
	if(activated && inserted_battery && inserted_battery.battery_effect)
		is_emitting = "_on"
		set_light(2, 1, "#8f66f4")
	else
		set_light(0)
	var/power_battery = (inserted_battery.stored_charge / inserted_battery.capacity) * 100
	power_battery = min(power_battery, 100)
	icon_state = "utilizer[round(power_battery, 25)][is_emitting]"

/obj/item/weapon/xenoarch_utilizer/Destroy()
	STOP_PROCESSING(SSobj, src)
	..()

/obj/item/weapon/xenoarch_utilizer/attack(mob/living/M, mob/living/user, def_zone)
	if (!istype(M))
		return

	if(!isnull(inserted_battery) && activated && inserted_battery.battery_effect && inserted_battery.battery_effect.effect == EFFECT_TOUCH )
		inserted_battery.battery_effect.DoEffectTouch(M)
		inserted_battery.stored_charge -= min(inserted_battery.stored_charge, 20) // we are spending quite a big amount of energy doing this
		user.visible_message("<span class='notice'>[user] taps [M] with [src], and it shudders on contact.</span>")
	else
		user.visible_message("<span class='notice'>[user] taps [M] with [src], but nothing happens.</span>")

	// admin logging
	user.lastattacked = M
	M.lastattacker = user

	if(inserted_battery.battery_effect)
		user.attack_log += "\[[time_stamp()]\]<font color='red'> Tapped [M.name] ([M.ckey]) with [name] (EFFECT: [inserted_battery.battery_effect.effecttype])</font>"
		M.attack_log += "\[[time_stamp()]\]<font color='orange'> Tapped by [user.name] ([user.ckey]) with [name] (EFFECT: [inserted_battery.battery_effect.effecttype])</font>"
		msg_admin_attack("[key_name(user)] tapped [key_name(M)] with [name] (EFFECT: [inserted_battery.battery_effect.effecttype])" )
