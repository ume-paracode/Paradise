/obj/item/weapon/gun/projectile/shotgun
	name = "shotgun"
	desc = "A traditional shotgun with wood furniture and a four-shell capacity underneath."
	icon_state = "shotgun"
	item_state = "shotgun"
	w_class = 4.0
	force = 10
	flags = CONDUCT
	slot_flags = SLOT_BACK
	origin_tech = "combat=4;materials=2"
	var/recentpump = 0 // to prevent spammage
	var/pumped = 0
	mag_type = "/obj/item/ammo_box/magazine/internal/shot"

/obj/item/weapon/gun/projectile/shotgun/attackby(var/obj/item/A as obj, mob/user as mob)
	var/num_loaded = 0
	if(istype(A, /obj/item/ammo_box))
		var/obj/item/ammo_box/AM = A
		for(var/obj/item/ammo_casing/AC in AM.stored_ammo)
			var/didload = magazine.give_round(AC)
			if(didload)
				AM.stored_ammo -= AC
				num_loaded++
			if(!didload || !magazine.multiload)
				break
	if(istype(A, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/AC = A
		if(magazine && magazine.give_round(AC))
			user.drop_item()
			AC.loc = src
			num_loaded++
	if(num_loaded)
		user << "<span class='notice'>You load [num_loaded] shell\s into \the [src]!</span>"
		A.update_icon()
		update_icon()


/obj/item/weapon/gun/projectile/shotgun/process_chambered()
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(isnull(AC) || !istype(AC))
		return 0
	if(AC.BB)
		if(AC.reagents && AC.BB.reagents)
			var/datum/reagents/casting_reagents = AC.reagents
			casting_reagents.trans_to(AC.BB, casting_reagents.total_volume) //For chemical darts
			casting_reagents.delete()
		in_chamber = AC.BB //Load projectile into chamber.
		AC.BB.loc = src //Set projectile loc to gun.
		AC.BB = null
		AC.update_icon()
		return 1
	return 0


/obj/item/weapon/gun/projectile/shotgun/attack_self(mob/living/user as mob)
	if(recentpump)	return
	pump(user)
	recentpump = 1
	spawn(10)
		recentpump = 0
	return


/obj/item/weapon/gun/projectile/shotgun/proc/pump(mob/M as mob)
	playsound(M, 'sound/weapons/shotgunpump.ogg', 60, 1)
	pumped = 0
	if(chambered)//We have a shell in the chamber
		chambered.loc = get_turf(src)//Eject casing
		chambered.SpinAnimation(5, 1)
		chambered = null
		if(in_chamber)
			in_chamber = null
	if(!magazine.ammo_count())	return 0
	var/obj/item/ammo_casing/AC = magazine.get_round() //load next casing.
	chambered = AC
	update_icon()	//I.E. fix the desc
	return 1

/obj/item/weapon/gun/projectile/shotgun/examine()
	..()
	if (chambered)
		usr << "A [chambered.BB ? "live" : "spent"] one is in the chamber."

/obj/item/weapon/gun/projectile/shotgun/combat
	name = "combat shotgun"
	desc = "A traditional shotgun with tactical furniture and an eight-shell capacity underneath."
	icon_state = "cshotgun"
	origin_tech = "combat=5;materials=2"
	mag_type = "/obj/item/ammo_box/magazine/internal/shotcom"
	w_class = 5

/obj/item/weapon/gun/projectile/shotgun/riot //for spawn in the armory
	name = "riot shotgun"
	desc = "A sturdy shotgun with a longer magazine and a fixed tactical stock designed for non-lethal riot control."
	icon_state = "riotshotgun"
	mag_type = "/obj/item/ammo_box/magazine/internal/shotriot"
	sawn_desc = "Come with me if you want to live."

/obj/item/weapon/gun/projectile/shotgun/riot/attackby(var/obj/item/A as obj, mob/user as mob)
	..()
	if(istype(A, /obj/item/weapon/circular_saw) || istype(A, /obj/item/weapon/melee/energy) || istype(A, /obj/item/weapon/pickaxe/plasmacutter))
		sawoff(user)

/obj/item/weapon/gun/projectile/revolver/doublebarrel
	name = "double-barreled shotgun"
	desc = "A true classic."
	icon_state = "dshotgun"
	item_state = "shotgun"
	w_class = 4.0
	force = 10
	flags = CONDUCT
	slot_flags = SLOT_BACK
	origin_tech = "combat=3;materials=1"
	mag_type = "/obj/item/ammo_box/magazine/internal/cylinder/dualshot"
	sawn_desc = "Omar's coming!"

/obj/item/weapon/gun/projectile/revolver/doublebarrel/attackby(var/obj/item/A as obj, mob/user as mob)
	..()
	if(istype(A, /obj/item/ammo_box) || istype(A, /obj/item/ammo_casing))
		chamber_round()
	if(istype(A, /obj/item/weapon/circular_saw) || istype(A, /obj/item/weapon/melee/energy) || istype(A, /obj/item/weapon/pickaxe/plasmacutter))
		sawoff(user)

/obj/item/weapon/gun/projectile/proc/sawoff(mob/user as mob)
	user << "<span class='notice'>You begin to shorten \the [src].</span>"
	if(get_ammo())
		afterattack(user, user)
		playsound(user, fire_sound, 50, 1)
		user.visible_message("<span class='danger'>The [src] goes off!</span>", "<span class='danger'>The [src] goes off in your face!</span>")
		return
	if(do_after(user, 30))
		name = "sawn-off [src.name]"
		desc = sawn_desc
		icon_state = initial(icon_state) + "-sawn"
		w_class = 3.0
		item_state = "gun"
		slot_flags &= ~SLOT_BACK	//you can't sling it on your back
		slot_flags |= SLOT_BELT		//but you can wear it on your belt (poorly concealed under a trenchcoat, ideally)
		user << "<span class='warning'>You shorten \the [src]!</span>"
		update_icon()
		return

/obj/item/weapon/gun/projectile/revolver/doublebarrel/attack_self(mob/living/user as mob)
	var/num_unloaded = 0
	while (get_ammo() > 0)
		var/obj/item/ammo_casing/CB
		CB = magazine.get_round(0)
		chambered = null
		CB.loc = get_turf(src.loc)
		CB.update_icon()
		num_unloaded++
	if (num_unloaded)
		user << "<span class = 'notice'>You break open \the [src] and unload [num_unloaded] shell\s.</span>"
	else
		user << "<span class='notice'>[src] is empty.</span>"

// IMPROVISED SHOTGUN //

/obj/item/weapon/gun/projectile/revolver/doublebarrel/improvised
	name = "improvised shotgun"
	desc = "Essentially a tube that aims shotgun shells."
	icon_state = "ishotgun"
	item_state = "shotgun"
	w_class = 4.0
	force = 10
	origin_tech = "combat=2;materials=2"
	mag_type = "/obj/item/ammo_box/magazine/internal/cylinder/improvised"
	sawn_desc = "I'm just here for the gasoline."

/obj/item/weapon/gun/projectile/revolver/doublebarrel/improvised/attackby(var/obj/item/A as obj, mob/user as mob)
	..()
	if(istype(A, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = A
		if(C.use(10))
			flags =  CONDUCT
			slot_flags = SLOT_BACK
			icon_state = "ishotgunsling"
			user << "<span class='notice'>You tie the lengths of cable to the shotgun, making a sling.</span>"
			update_icon()
		else
			user << "<span class='warning'>You need at least ten lengths of cable if you want to make a sling.</span>"
			return