/obj/item/weapon/grenade
	name = "grenade"
	desc = "A hand held grenade, with an adjustable timer."
	w_class = ITEM_SIZE_SMALL
	icon = 'icons/obj/grenade.dmi'
	icon_state = "grenade"
	item_state = "flashbang"
	throw_speed = 4
	throw_range = 20
	flags = CONDUCT
	slot_flags = SLOT_FLAGS_BELT
	var/active = 0
	var/det_time = 50

	action_button_name = "Activate Grenade"

/obj/item/weapon/grenade/proc/clown_check(mob/living/user)
	if((CLUMSY in user.mutations) && prob(50))
		to_chat(user, "<span class='warning'>Huh? How does this thing work?</span>")

		activate(user)
		add_fingerprint(user)
		spawn(5)
			prime()
		return 0
	return 1


/*/obj/item/weapon/grenade/afterattack(atom/target, mob/user)
	if (istype(target, /obj/item/weapon/storage)) return ..() // Trying to put it in a full container
	if (istype(target, /obj/item/weapon/gun/grenadelauncher)) return ..()
	if((user.get_active_hand() == src) && (!active) && (clown_check(user)) && target.loc != src.loc)
		to_chat(user, "<span class='warning'>You prime the [name]! [det_time/10] seconds!</span>")
		active = 1
		icon_state = initial(icon_state) + "_active"
		playsound(src, 'sound/weapons/armbomb.ogg', VOL_EFFECTS_MASTER, null, null, -3)
		spawn(det_time)
			prime()
			return
		user.dir = get_dir(user, target)
		user.drop_item()
		var/t = (isturf(target) ? target : target.loc)
		walk_towards(src, t, 3)
	return*/


/obj/item/weapon/grenade/examine(mob/user)
	..()
	if(src in user)
		if(det_time > 1)
			to_chat(user, "The timer is set to [det_time/10] seconds.")
		else
			to_chat(user, "\The [src] is set for instant detonation.")


/obj/item/weapon/grenade/attack_self(mob/user)
	if(!active)
		if(clown_check(user))
			to_chat(user, "<span class='warning'>You prime \the [name]! [det_time/10] seconds!</span>")

			activate(user)
			add_fingerprint(user)
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.throw_mode_on()
	return


/obj/item/weapon/grenade/proc/activate(mob/user)
	if(active)
		return

	if(user)
		msg_admin_attack("[user.name] ([user.ckey]) primed \a [src] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")

	icon_state = initial(icon_state) + "_active"
	active = 1
	playsound(src, 'sound/weapons/armbomb.ogg', VOL_EFFECTS_MASTER, null, null, -3)

	spawn(det_time)
		prime()
		return


/obj/item/weapon/grenade/proc/prime()
//	playsound(src, 'sound/items/Welder2.ogg', VOL_EFFECTS_MASTER, 25)
	var/turf/T = get_turf(src)
	if(T)
		T.hotspot_expose(700,125)


/obj/item/weapon/grenade/attackby(obj/item/weapon/W, mob/user)
	if(isscrewdriver(W))
		switch(det_time)
			if ("1")
				det_time = 10
				to_chat(user, "<span class='notice'>You set the [name] for 1 second detonation time.</span>")
			if ("10")
				det_time = 30
				to_chat(user, "<span class='notice'>You set the [name] for 3 second detonation time.</span>")
			if ("30")
				det_time = 50
				to_chat(user, "<span class='notice'>You set the [name] for 5 second detonation time.</span>")
			if ("50")
				det_time = 1
				to_chat(user, "<span class='notice'>You set the [name] for instant detonation.</span>")
		add_fingerprint(user)
	..()
	return

/obj/item/weapon/grenade/attack_hand()
	walk(src, null, null)
	..()
	return

/obj/item/weapon/grenade/attack_paw(mob/user)
	return attack_hand(user)

/obj/item/weapon/grenade/syndieminibomb
	desc = "A syndicate manufactured explosive used to sow destruction and chaos."
	name = "syndicate minibomb"
	icon_state = "syndicate"
	item_state = "flashbang"
	origin_tech = "materials=3;magnets=4;syndicate=4"

/obj/item/weapon/grenade/syndieminibomb/prime()
	explosion(src.loc,1,2,4,5)
	qdel(src)
