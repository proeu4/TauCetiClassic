/****************************************************
				INTERNAL ORGANS
****************************************************/
/obj/item/organ/internal
	parent_bodypart = BP_CHEST

	// Strings.
	var/organ_tag   = null      // Unique identifier.

	// Damage vars.
	var/min_bruised_damage = 10 // Damage before considered bruised
	var/damage = 0              // Amount of damage to the organ

	// Will be moved, removed or refactored.
	var/process_accuracy = 0    // Damage multiplier for organs, that have damage values.
	var/robotic = 0             // For being a robot

/obj/item/organ/internal/insert_organ()
	..()

	owner.organs += src
	owner.organs_by_name[organ_tag] = src

	if(parent)
		parent.bodypart_organs += src


/obj/item/organ/internal/proc/rejuvenate()
	damage = 0

/obj/item/organ/internal/proc/is_bruised()
	// If not robotic, and owner has stabyzol in bloodstream, we are considered not bruised.
	if(!robotic && owner.reagents.has_reagent("stabyzol"))
		return FALSE
	return damage >= min_bruised_damage

/obj/item/organ/internal/proc/is_broken()
	// If not robotic, and owner has stabyzol in bloodstream, we are considered not bruised.
	if(!robotic && owner.reagents.has_reagent("stabyzol"))
		return FALSE
	return damage >= min_broken_damage


/obj/item/organ/internal/process()
	//Process infections

	if (robotic >= 2 || (owner.species && owner.species.flags[IS_PLANT]))	//TODO make robotic organs and bodyparts separate types instead of a flag
		germ_level = 0
		return

	if(owner.bodytemperature >= 170)	//cryo stops germs from moving and doing their bad stuffs
		//** Handle antibiotics and curing infections
		handle_antibiotics()

		//** Handle the effects of infections
		var/antibiotics = owner.reagents.get_reagent_amount("spaceacillin")

		if (germ_level > 0 && germ_level < INFECTION_LEVEL_ONE/2 && prob(30))
			germ_level--

		if (germ_level >= INFECTION_LEVEL_ONE/2)
			//aiming for germ level to go from ambient to INFECTION_LEVEL_TWO in an average of 15 minutes
			if(antibiotics < 5 && prob(round(germ_level/6)))
				germ_level++

		if (germ_level >= INFECTION_LEVEL_TWO)
			var/obj/item/organ/external/BP = owner.bodyparts_by_name[parent_bodypart]
			//spread germs
			if (antibiotics < 5 && BP.germ_level < germ_level && ( BP.germ_level < INFECTION_LEVEL_ONE * 2 || prob(30) ))
				BP.germ_level++

			if (prob(3))	//about once every 30 seconds
				take_damage(1,silent=prob(30))

/obj/item/organ/internal/proc/take_damage(amount, silent=0)
	if(src.robotic == 2)
		src.damage += (amount * 0.8)
	else
		src.damage += amount

	var/obj/item/organ/external/BP = owner.bodyparts_by_name[parent_bodypart]
	if (!silent)
		owner.custom_pain("Something inside your [BP.name] hurts a lot.", 1)

/obj/item/organ/internal/emp_act(severity)
	switch(robotic)
		if(0)
			return
		if(1)
			switch (severity)
				if (1.0)
					take_damage(20,0)
					return
				if (2.0)
					take_damage(7,0)
					return
				if(3.0)
					take_damage(3,0)
					return
		if(2)
			switch (severity)
				if (1.0)
					take_damage(40,0)
					return
				if (2.0)
					take_damage(15,0)
					return
				if(3.0)
					take_damage(10,0)
					return

/obj/item/organ/internal/proc/mechanize() //Being used to make robutt hearts, etc
	robotic = 2

/obj/item/organ/internal/proc/mechassist() //Used to add things like pacemakers, etc
	robotic = 1
	min_bruised_damage = 15
	min_broken_damage = 35

/****************************************************
				ORGANS DEFINES
****************************************************/

/obj/item/organ/internal/heart
	name = "heart"
	organ_tag = O_HEART
	parent_bodypart = BP_CHEST

/obj/item/organ/internal/heart/ipc
	name = "servomotor"

/obj/item/organ/internal/lungs
	name = "lungs"
	organ_tag = O_LUNGS
	parent_bodypart = BP_CHEST

	var/has_gills = FALSE

/obj/item/organ/internal/lungs/skrell
	name = "respiration sac"
	has_gills = TRUE

/obj/item/organ/internal/lungs/diona
	name = "virga inopinatus"
	process_accuracy = 10

/obj/item/organ/internal/lungs/ipc
	name = "cooling element"

/obj/item/organ/internal/lungs/process()
	..()
	if (owner.species && owner.species.flags[NO_BREATHE])
		return
	if (germ_level > INFECTION_LEVEL_ONE)
		if(prob(5))
			owner.emote("cough")		//respitory tract infection

	if(is_bruised())
		if(prob(2))
			owner.emote("gasp", 2, "coughs up blood!", TRUE)
			owner.drip(10)
		if(prob(4))
			owner.emote("gasp", 2, "gasps for air!")
			owner.losebreath += 15

/obj/item/organ/internal/lungs/diona/process()
	..()
	if(is_bruised())
		if(prob(2))
			owner.emote("me", 2, "annoyingly creaks!")
			owner.drip(10)
		if(prob(4))
			owner.emote("me", 2, "smells of rot.")
			owner.apply_damage(rand(1,15), TOX, BP_CHEST, 0)		//Diona's lungs are used to dispose of toxins, so when lungs are broken, diona gets intoxified.
	if(owner.life_tick % process_accuracy == 0)
		if(damage < 0)
			damage = 0

		if(owner.getToxLoss() >= 60 && !owner.reagents.has_reagent("anti_toxin"))
			if(damage < min_broken_damage)
				damage += 0.2 * process_accuracy
			else
				var/obj/item/organ/internal/IO = pick(owner.organs)
				if(IO)
					IO.damage += 0.2  * process_accuracy

		if(damage >= min_bruised_damage)
			for(var/datum/reagent/R in owner.reagents.reagent_list)
				if(istype(R, /datum/reagent/consumable/ethanol))
					owner.adjustToxLoss(0.1 * process_accuracy)
				if(istype(R, /datum/reagent/toxin))
					owner.adjustToxLoss(0.3 * process_accuracy)

/obj/item/organ/internal/liver
	name = "liver"
	organ_tag = O_LIVER
	parent_bodypart = BP_CHEST
	process_accuracy = 10

/obj/item/organ/internal/liver/diona
	name = "chlorophyll sac"

/obj/item/organ/internal/liver/ipc
	name = "accumulator"

/obj/item/organ/internal/liver/ipc/atom_init()
	. = ..()
	new/obj/item/weapon/stock_parts/cell/crap/(src)

/obj/item/organ/internal/liver/process()
	..()
	if (germ_level > INFECTION_LEVEL_ONE)
		if(prob(1))
			to_chat(owner, "<span class='warning'>Your skin itches.</span>")
	if (germ_level > INFECTION_LEVEL_TWO)
		if(prob(1))
			INVOKE_ASYNC(owner, /mob/living/carbon/human.proc/vomit)

	if(owner.life_tick % process_accuracy == 0)
		if(src.damage < 0)
			src.damage = 0

		//High toxins levels are dangerous
		if(owner.getToxLoss() >= 60 && !owner.reagents.has_reagent("anti_toxin"))
			//Healthy liver suffers on its own
			if (src.damage < min_broken_damage)
				src.damage += 0.2 * process_accuracy
			//Damaged one shares the fun
			else
				var/obj/item/organ/internal/IO = pick(owner.organs)
				if(IO)
					IO.damage += 0.2  * process_accuracy

		//Detox can heal small amounts of damage
		if (src.damage && src.damage < src.min_bruised_damage && owner.reagents.has_reagent("anti_toxin"))
			src.damage -= 0.2 * process_accuracy

		// Damaged liver means some chemicals are very dangerous
		if(src.damage >= src.min_bruised_damage)
			for(var/datum/reagent/R in owner.reagents.reagent_list)
				// Ethanol and all drinks are bad
				if(istype(R, /datum/reagent/consumable/ethanol))
					owner.adjustToxLoss(0.1 * process_accuracy)
				// Can't cope with toxins at all
				if(istype(R, /datum/reagent/toxin))
					owner.adjustToxLoss(0.3 * process_accuracy)

/obj/item/organ/internal/liver/ipc/process()
	var/obj/item/weapon/stock_parts/cell/C = locate(/obj/item/weapon/stock_parts/cell) in src
	if(damage && C)
		C.charge = owner.nutrition
		if(owner.nutrition > (C.maxcharge - damage * 5))
			owner.nutrition = C.maxcharge - damage * 5
	else if(!C)
		if(!owner.is_bruised_organ(O_KIDNEYS) && prob(2))
			to_chat(owner, "<span class='warning bold'>%ACCUMULATOR% DAMAGED BEYOND FUNCTION. SHUTTING DOWN.</span>")
		owner.SetParalysis(5)
		owner.eye_blurry = 5
		owner.silent = 5

/obj/item/organ/internal/kidneys
	name = "kidneys"
	organ_tag = O_KIDNEYS
	parent_bodypart = BP_CHEST

/obj/item/organ/internal/kidneys/diona
	name = "vacuole"
	parent_bodypart = BP_GROIN

/obj/item/organ/internal/kidneys/ipc
	name = "self-diagnosis unit"
	parent_bodypart = BP_GROIN

/obj/item/organ/internal/kidneys/diona/process()
	if(damage)
		if(prob(10))
			damage -= 1
		if(prob(2))
			to_chat(owner, "<span class='warning'>You notice slight discomfort in your groin.</span>")

/obj/item/organ/internal/kidneys/ipc/process()
	for(var/obj/item/organ/internal/IO in owner.organs)
		if(IO.is_bruised() && prob(4))
			to_chat(owner, "<span class='warning bold'>%[uppertext_(IO)]% INJURY DETECTED. CEASE DAMAGE TO %ACCUMULATOR%. REQUEST ASSISTANCE.</span>")

/obj/item/organ/internal/brain
	name = "brain"
	organ_tag = O_BRAIN
	parent_bodypart = BP_HEAD

/obj/item/organ/internal/brain/diona
	name = "main node nymph"
	parent_bodypart = BP_CHEST

/obj/item/organ/internal/brain/ipc
	name = "positronic brain"
	parent_bodypart = BP_CHEST

/obj/item/organ/internal/eyes
	name = "eyes"
	organ_tag = O_EYES
	parent_bodypart = BP_HEAD

/obj/item/organ/internal/eyes/ipc
	name = "cameras"
	robotic = 2

/obj/item/organ/internal/eyes/process() //Eye damage replaces the old eye_stat var.
	..()
	if(is_bruised())
		owner.eye_blurry = 20
	if(is_broken())
		owner.eye_blind = 20
