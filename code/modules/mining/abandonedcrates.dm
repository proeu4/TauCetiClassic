/obj/structure/closet/crate/secure/loot
	name = "abandoned crate"
	desc = "What could be inside?"
	icon_state = "securecrate"
	icon_opened = "securecrateopen"
	icon_closed = "securecrate"
	var/code = null
	var/lastattempt = null
	var/attempts = 3
	locked = 1
	var/min = 1
	var/max = 10

/obj/structure/closet/crate/secure/loot/atom_init()
	. = ..()
	code = rand(min,max)

/obj/structure/closet/crate/secure/loot/PopulateContents()
	var/loot = rand(1,30)
	switch(loot)
		if(1)
			new/obj/item/weapon/reagent_containers/food/drinks/bottle/rum(src)
			new/obj/item/weapon/reagent_containers/food/snacks/grown/ambrosiadeus(src)
			new/obj/item/weapon/reagent_containers/food/drinks/bottle/whiskey(src)
			new/obj/item/weapon/lighter/zippo(src)
		if(2)
			new/obj/item/weapon/pickaxe/drill(src)
			new/obj/item/device/taperecorder(src)
			new/obj/item/clothing/suit/space(src)
			new/obj/item/clothing/head/helmet/space(src)
		if(3)
			return
		if(4)
			new/obj/item/weapon/reagent_containers/glass/beaker/bluespace(src)
		if(5 to 6)
			for (var/i in 1 to 10)
				new/obj/item/weapon/ore/diamond(src)
		if(7)
			return
		if(8)
			return
		if(9)
			for (var/i in 1 to 3)
				new/obj/machinery/hydroponics/constructable(src)
		if(10)
			for (var/i in 1 to 3)
				new/obj/item/weapon/reagent_containers/glass/beaker/noreact(src)
		if(11 to 12)
			for (var/i in 1 to 9)
				new/obj/item/bluespace_crystal(src)
		if(13)
			new/obj/item/weapon/melee/classic_baton(src)
		if(14)
			return
		if(15)
			new/obj/item/clothing/under/chameleon(src)
			for (var/i in 1 to 7)
				new/obj/item/clothing/accessory/tie/horrible(src)
		if(16)
			new/obj/item/clothing/under/shorts(src)
			new/obj/item/clothing/under/shorts/red(src)
			new/obj/item/clothing/under/shorts/blue(src)
		//Dummy crates start here.
		if(17 to 29)
			return
		//Dummy crates end here.
		if(30)
			new/obj/item/weapon/melee/baton(src)

/obj/structure/closet/crate/secure/loot/togglelock(mob/user)
	if(locked)
		to_chat(user, "<span class='notice'>The crate is locked with a Deca-code lock.</span>")
		var/input = input(usr, "Enter digit from [min] to [max].", "Deca-Code Lock", "") as num
		if(in_range(src, user))
			input = Clamp(input, 0, 10)
			if (input == code)
				to_chat(user, "<span class='notice'>The crate unlocks!</span>")
				locked = 0
				overlays.Cut()
				overlays += greenlight
			else if (input == null || input > max || input < min)
				to_chat(user, "<span class='notice'>You leave the crate alone.</span>")
			else
				to_chat(user, "<span class='warning'>A red light flashes.</span>")
				lastattempt = input
				attempts--
				if (attempts == 0)
					to_chat(user, "<span class='danger'>The crate's anti-tamper system activates!</span>")
					var/turf/T = get_turf(src.loc)
					explosion(T, 0, 0, 0, 1)
					qdel(src)
					return
		else
			to_chat(user, "<span class='notice'>You attempt to interact with the device using a hand gesture, but it appears this crate is from before the DECANECT came out.</span>")
			return
	else
		return ..()

/obj/structure/closet/crate/secure/loot/attackby(obj/item/weapon/W, mob/user)
	if(locked)
		user.SetNextMove(CLICK_CD_INTERACT)
		if (ismultitool(W))
			to_chat(user, "<span class='notice'>DECA-CODE LOCK REPORT:</span>")
			if (attempts == 1)
				to_chat(user, "<span class='warning'>* Anti-Tamper Bomb will activate on next failed access attempt.</span>")
			else
				to_chat(user, "<span class='notice'>* Anti-Tamper Bomb will activate after [src.attempts] failed access attempts.</span>")
			if (lastattempt == null)
				to_chat(user, "<span class='notice'> has been made to open the crate thus far.</span>")
				return
			// hot and cold
			if (code > lastattempt)
				to_chat(user, "<span class='notice'>* Last access attempt lower than expected code.</span>")
			else
				to_chat(user, "<span class='notice'>* Last access attempt higher than expected code.</span>")
		else
			..()
	else
		..()

/obj/structure/closet/crate/secure/loot/emag_act(mob/user)
	if(locked)
		to_chat(user, "<span class='notice'>The crate unlocks!</span>")
		locked = 0
		return TRUE
	return FALSE
