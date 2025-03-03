/obj/effect/blob/factory
	name = "factory blob"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_factory"
	health = 100
	fire_resist = 2
	var/list/spores = list()
	var/max_spores = 3
	var/spore_delay = 0

/obj/effect/blob/factory/update_icon()
	if(health <= 0)
		qdel(src)

/obj/effect/blob/factory/Destroy()
	for(var/mob/living/simple_animal/hostile/blobspore/spore in spores)
		if(spore.factory == src)
			spore.factory = null
	return ..()

/obj/effect/blob/factory/PulseAnimation(var/activate = 0)
	if(activate)
		..()
	return

/obj/effect/blob/factory/run_action()
	if(spores.len >= max_spores)
		return 0
	if(spore_delay > world.time)
		return 0
	spore_delay = world.time + 100 // 10 seconds
	PulseAnimation(1)
	new/mob/living/simple_animal/hostile/blobspore(src.loc, src)
	return 0


/mob/living/simple_animal/hostile/blobspore
	name = "blob"
	desc = "Some blob thing."
	icon = 'icons/mob/blob.dmi'
	icon_state = "blobpod"
	icon_living = "blobpod"
	pass_flags = PASSBLOB
	health = 40
	maxHealth = 40
	melee_damage_lower = 2
	melee_damage_upper = 4
	attacktext = "hits"
	attack_sound = list('sound/weapons/genhit1.ogg')
	var/obj/effect/blob/factory/factory = null
	var/is_zombie = 0
	faction = "blob"
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	maxbodytemp = 360

/mob/living/simple_animal/hostile/blobspore/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	..()
	adjustBruteLoss(Clamp(0.01 * exposed_temperature, 1, 5))

/mob/living/simple_animal/hostile/blobspore/blob_act()
	return

/mob/living/simple_animal/hostile/blobspore/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /obj/effect/blob))
		return 1
	return ..()

/mob/living/simple_animal/hostile/blobspore/atom_init(mapload, obj/effect/blob/factory/linked_node)
	if(istype(linked_node))
		factory = linked_node
		factory.spores += src
	. = ..()

/mob/living/simple_animal/hostile/blobspore/Life()

	if(!is_zombie && isturf(src.loc))
		for(var/mob/living/carbon/human/H in oview(src,1)) //Only for corpse right next to/on same tile
			if(H.stat == DEAD)
				Zombify(H)
				break
	..()

/mob/living/simple_animal/hostile/blobspore/proc/Zombify(mob/living/carbon/human/H)
	if(H.wear_suit)
		var/obj/item/clothing/suit/armor/A = H.wear_suit
		if(A.armor && A.armor["melee"])
			maxHealth += A.armor["melee"] //That zombie's got armor, I want armor!
	maxHealth += 40
	health = maxHealth
	name = "blob zombie"
	desc = "A shambling corpse animated by the blob."
	melee_damage_lower = 10
	melee_damage_upper = 15
	icon = H.icon
	icon_state = "husk_s"
	H.h_style = null
	H.update_hair()
	overlays = H.overlays
	overlays += image('icons/mob/blob.dmi', icon_state = "blob_head")
	H.loc = src
	is_zombie = 1
	loc.visible_message("<span class='warning'> The corpse of [H.name] suddenly rises!</span>")

/mob/living/simple_animal/hostile/blobspore/death()
// On death, create a small smoke of harmful gas (s-Acid)
	var/datum/effect/effect/system/smoke_spread/chem/S = new
	var/turf/location = get_turf(src)

	// Create the reagents to put into the air, s-acid is yellow and stings a little
	create_reagents(25)
	reagents.add_reagent("spore", 25)

	// Attach the smoke spreader and setup/start it.
	S.attach(location)
	S.set_up(reagents, 1, 1, location, 15, 1) // only 1-2 smoke cloud
	S.start()

	qdel(src)

/mob/living/simple_animal/hostile/blobspore/Destroy()
	if(factory)
		factory.spores -= src
	if(contents)
		for(var/mob/M in contents)
			M.loc = src.loc
	return ..()

/datum/reagent/toxin/spore
	name = "Spore Toxin"
	id = "spore"
	description = "A toxic spore cloud which blocks vision when ingested."
	color = "#9acd32"
	toxpwr = 0.5

/datum/reagent/toxin/spore/on_general_digest(mob/living/M)
	..()
	M.damageoverlaytemp = 60
	M.eye_blurry = max(M.eye_blurry, 3)
