
/obj/item/weapon/reagent_containers/robodropper
	name = "Industrial Dropper"
	desc = "A larger dropper. Transfers 10 units."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dropper"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(1,2,3,4,5,6,7,8,9,10)
	volume = 10
	var/filled = 0

/obj/item/weapon/reagent_containers/robodropper/afterattack(obj/target, mob/user , flag)
	if(!target.reagents) return

	if(filled)

		if(target.reagents.total_volume >= target.reagents.maximum_volume)
			to_chat(user, "<span class='warning'>[target] is full.</span>")
			return

		if(!target.is_open_container() && !ismob(target) && !istype(target,/obj/item/weapon/reagent_containers/food)) //You can inject humans and food but you cant remove the shit.
			to_chat(user, "<span class='warning'>You cannot directly fill this object.</span>")
			return


		var/trans = 0

		if(ismob(target))
			if(istype(target , /mob/living/carbon/human))
				var/mob/living/carbon/human/victim = target

				var/obj/item/safe_thing = null
				if( victim.wear_mask )
					if ( victim.wear_mask.flags & MASKCOVERSEYES )
						safe_thing = victim.wear_mask
				if( victim.head )
					if ( victim.head.flags & MASKCOVERSEYES )
						safe_thing = victim.head
				if(victim.glasses)
					if ( !safe_thing )
						safe_thing = victim.glasses

				if(safe_thing)
					if(!safe_thing.reagents)
						safe_thing.create_reagents(100)
					trans = src.reagents.trans_to(safe_thing, amount_per_transfer_from_this)

					for(var/mob/O in viewers(world.view, user))
						O.show_message(text("<span class='warning'><B>[] tries to squirt something into []'s eyes, but fails!</B></span>", user, target), 1)
					spawn(5)
						src.reagents.reaction(safe_thing, TOUCH)


					to_chat(user, "<span class='notice'>You transfer [trans] units of the solution.</span>")
					if (src.reagents.total_volume<=0)
						filled = 0
						icon_state = "dropper[filled]"
					return


			for(var/mob/O in viewers(world.view, user))
				O.show_message(text("<span class='warning'><B>[] squirts something into []'s eyes!</B></span>", user, target), 1)
			src.reagents.reaction(target, TOUCH)

			var/mob/M = target
			var/list/injected = list()
			for(var/datum/reagent/R in src.reagents.reagent_list)
				injected += R.name
			var/contained = english_list(injected)
			M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been squirted with [src.name] by [user.name] ([user.ckey]). Reagents: [contained]</font>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to squirt [M.name] ([M.key]). Reagents: [contained]</font>")
			msg_admin_attack("[user.name] ([user.ckey]) squirted [M.name] ([M.key]) with [src.name]. Reagents: [contained] (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")


		trans = src.reagents.trans_to(target, amount_per_transfer_from_this)
		to_chat(user, "<span class='notice'>You transfer [trans] units of the solution.</span>")
		if (src.reagents.total_volume<=0)
			filled = 0
			icon_state = "dropper"

	else

		if(!target.is_open_container() && !istype(target,/obj/structure/reagent_dispensers))
			to_chat(user, "<span class='warning'>You cannot directly remove reagents from [target].</span>")
			return

		if(!target.reagents.total_volume)
			to_chat(user, "<span class='warning'>[target] is empty.</span>")
			return

		var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this)

		to_chat(user, "<span class='notice'>You fill the dropper with [trans] units of the solution.</span>")

		filled = 1
		icon_state = "dropper[filled]"

	return
