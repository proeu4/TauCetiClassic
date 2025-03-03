/datum/job

	//The name of the job
	var/title = "NOPE"

	var/list/access = list()

	//Bitflags for the job
	var/flag = 0
	var/department_flag = 0

	//Players will be allowed to spawn in as jobs that are set to "Station"
	var/faction = "None"

	//How many players can be this job
	var/total_positions = 0

	//How many players can spawn in as this job
	var/spawn_positions = 0

	//How many players have this job
	var/current_positions = 0

	//Supervisors, who this person answers to directly
	var/supervisors = ""

	//Sellection screen color
	var/selection_color = "#ffffff"

	//the type of the ID the player will have
	var/idtype = /obj/item/weapon/card/id

	//List of alternate titles, if any
	var/list/alt_titles

	//If this is set to 1, a text is printed to the player when jobs are assigned, telling him that he should let admins know that he has to disconnect.
	var/req_admin_notify

	//If you have use_age_restriction_for_jobs config option enabled and the database set up, this option will add a requirement for players to be at least minimal_player_age days old. (meaning they first signed in at least that many days before.)
	var/minimal_player_age = 0

	//If you have use_age_restriction_for_jobs config option enabled and the database set up, this option will add a requirement for players to be at least minimal_player_ingame_minutes ingame minutes old. (meaning they must play a game.)
	var/minimal_player_ingame_minutes = 0

	//Should we spawn and give him his selected loadout items
	var/give_loadout_items = TRUE

	var/list/restricted_species = list()

/datum/job/proc/equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	return TRUE

/datum/job/proc/get_access()
	return access.Copy()

//If the configuration option is set to require players to be logged as old enough to play certain jobs, then this proc checks that they are, otherwise it just returns 1
/datum/job/proc/player_old_enough(client/C)
	if(config.use_ingame_minutes_restriction_for_jobs)
		if(available_in_real_minutes(C) == 0)
			return 1	//Available in 0 minutes = available right now = player is old enough to play.
	else
		if(available_in_days(C) == 0)
			return 1	//Available in 0 days = available right now = player is old enough to play.
	return 0


/datum/job/proc/is_species_permitted(client/C)
	if(!config.use_alien_job_restriction)
		return TRUE
	return !(C.prefs.species in restricted_species)

/datum/job/proc/available_in_days(client/C)
	if(!C)
		return 0
	if(!config.use_age_restriction_for_jobs)
		return 0
	if(!isnum(C.player_age))
		return 0 //This is only a number if the db connection is established, otherwise it is text: "Requires database", meaning these restrictions cannot be enforced
	if(!isnum(minimal_player_age))
		return 0

	return max(0, minimal_player_age - C.player_age)

/datum/job/proc/available_in_real_minutes(client/C)
	if(!C)
		return 0
	if(C.holder || C.deadmin_holder)
		return 0
	if(!config.use_age_restriction_for_jobs)
		return 0
	if(!isnum(C.player_ingame_age))
		return 0
	if(!isnum(minimal_player_ingame_minutes))
		return 0

	return max(0, minimal_player_ingame_minutes - C.player_ingame_age)

//Not sure where to put this proc, lets leave it here for now.
/proc/role_available_in_minutes(mob/M, role)
	if(!M || !istype(M) || !M.ckey)
		return 0
	var/client/C = M.client
	if(!C)
		return 0
	if(C.holder || C.deadmin_holder)
		return 0
	if(!config.use_age_restriction_for_jobs)
		return 0
	if(!config.use_ingame_minutes_restriction_for_jobs)
		return 0
	if(!isnum(C.player_ingame_age))
		return 0
	if(!(role in roles_ingame_minute_unlock))
		return 0

	return max(0, roles_ingame_minute_unlock[role] - C.player_ingame_age)

/datum/job/proc/apply_fingerprints(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(H.back)
		H.back.add_fingerprint(H,1)	//The 1 sets a flag to ignore gloves
		for(var/obj/item/I in H.back.contents)
			I.add_fingerprint(H,1)
	if(H.wear_id)
		H.wear_id.add_fingerprint(H,1)
	if(H.w_uniform)
		H.w_uniform.add_fingerprint(H,1)
	if(H.wear_suit)
		H.wear_suit.add_fingerprint(H,1)
	if(H.wear_mask)
		H.wear_mask.add_fingerprint(H,1)
	if(H.head)
		H.head.add_fingerprint(H,1)
	if(H.shoes)
		H.shoes.add_fingerprint(H,1)
	if(H.gloves)
		H.gloves.add_fingerprint(H,1)
	if(H.l_ear)
		H.l_ear.add_fingerprint(H,1)
	if(H.r_ear)
		H.r_ear.add_fingerprint(H,1)
	if(H.glasses)
		H.glasses.add_fingerprint(H,1)
	if(H.belt)
		H.belt.add_fingerprint(H,1)
		for(var/obj/item/I in H.belt.contents)
			I.add_fingerprint(H,1)
	if(H.s_store)
		H.s_store.add_fingerprint(H,1)
	if(H.l_store)
		H.l_store.add_fingerprint(H,1)
	if(H.r_store)
		H.r_store.add_fingerprint(H,1)
	return 1

/datum/job/proc/is_position_available()
	return (current_positions < total_positions) || (total_positions == -1)

/datum/job/proc/map_check()
	return TRUE