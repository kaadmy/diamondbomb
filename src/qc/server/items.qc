void() W_SetCurrentAmmo;
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */


void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};



/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float	oldz;

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
	if (!droptofloor())
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0)
		return 0;
	if ((!ignore) && (e.health >= other.max_health))
		return 0;
	healamount = ceil(healamount);

	e.health = e.health + healamount;
	if ((!ignore) && (e.health >= other.max_health))
		e.health = other.max_health;

	if (e.health > 200)
		e.health = 200;
	return 1;
};

float	H_MINI = 1;
float	H_MEDIUM = 2;
float	H_MEGA = 3;
.float	healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{
	self.touch = health_touch;

	if (self.spawnflags & H_MEDIUM)
	{
		precache_model("models/items/mediumhealth.md3");
		precache_sound("sounds/items/mediumhealth.wav");
		setmodel(self, "sounds/items/mediumhealth.md3");
		self.noise = "sounds/items/mediumhealth.wav";
		self.healamount = 50;
		self.healtype = 0;
	}
	else
	if (self.spawnflags & H_MEGA)
	{
		precache_model("models/items/megahealth.md3");
		precache_sound("sounds/items/megahealth.wav");
		setmodel(self, "sounds/items/megahealth.md3");
		self.noise = "sounds/items/megahealth.wav";
		self.healamount = 100;
		self.healtype = 0;
	}
	else
	{
		precache_model("models/items/minihealth.md3");
		precache_sound("sounds/items/minihealth.wav");
		setmodel(self, "sounds/items/minihealth.md3");
		self.noise = "sounds/items/minihealth.wav";
		self.healamount = 25;
		self.healtype = 0;
	}

	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


void() health_touch =
{
	local	string	s;

	if (other.classname != "player")
		return;

	if (self.healtype == 2) // Megahealth goes to 200
	{
		if (other.health >= 200)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}
	else
	if (self.healtype == 0) // Minihealth goes to 200
	{
		if (other.health >= 200)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}
	else // Mediumhealth goes to 100
	{
		if (!T_Heal(other, self.healamount, 0))
			return;
	}

// print the health you've gotten
	s = ftos(self.healamount);
	sprint(other, s);
	sprint(other, "hp\n");

// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd (other, "bf\n");

	self.model = string_null;
	self.solid = SOLID_NOT;

	// Megahealth = rot down the player's mega health
	if (self.healtype == 2)
	{
		other.items = other.items | IT_SUPERHEALTH;
		self.nextthink = time + 5;
		self.think = item_megahealth_rot;
		self.owner = other;
	}

	self.think = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void() item_megahealth_rot =
{
	other = self.owner;

	if (other.health > other.max_health)
	{
		other.health = other.health - 1;
		self.nextthink = time + 1;
		return;
	}

// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
	other.items = other.items - (other.items & IT_SUPERHEALTH);

	self.think = SUB_regen;
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch;

void() armor_touch =
{
	local	float	type, value, bit;

	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;

	if (self.classname == "item_armorshard")
	{
		type = 0.3;
		value = 25;
		bit = IT_ARMOR1;
	}
	if (self.classname == "item_mediumarmor")
	{
		type = 0.6;
		value = 50;
		bit = IT_ARMOR2;
	}
	if (self.classname == "item_megaarmor")
	{
		type = 0.8;
		value = 200;
		bit = IT_ARMOR3;
	}
	if (other.armortype*other.armorvalue >= type*value)
		return;

	other.armortype = type;
	other.armorvalue = value;
	other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;

	self.solid = SOLID_NOT;
	self.model = string_null;
	self.think = SUB_regen;

	sprint(other, "You got armor\n");
// armor touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armorshard =
{
	self.touch = armor_touch;
	precache_model ("models/items/armorshard.md3");
	setmodel (self, "models/items/armorshard.md3");
	self.noise = "sounds/items/armorshard.wav";
	self.skin = 0;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_mediumarmor=
{
	self.touch = armor_touch;
	precache_model ("models/items/mediumarmor.md3");
	setmodel (self, "models/items/mediumarmor.md3");
	self.noise = "sounds/items/mediumarmor.wav";
	self.skin = 1;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_megaarmor =
{
	self.touch = armor_touch;
	precache_model ("models/items/megaarmor.md3");
	setmodel (self, "models/items/megaarmor.md3");
	self.noise = "sounds/items/megaarmor.wav";
	self.skin = 2;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
	if (other.ammo_shells > 100)
		other.ammo_shells = 100;
	if (other.ammo_plasma > 200)
		other.ammo_plasma = 200;
	if (other.ammo_rockets > 100)
		other.ammo_rockets = 100;
	if (other.ammo_slugs > 100)
		other.ammo_slugs = 100;
};

/*
=============
weapon_touch
=============
*/
float() W_BestWeapon;

void() weapon_touch =
{
	local	float	hadammo, new, old;
	local	entity	stemp;
	local	float	leave;

	if (!(other.flags & FL_CLIENT))
		return;

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	self = stemp;

	if (self.classname == "weapon_plasmagun")
	{
		if (leave && (other.items & IT_PLASMAGUN) )
			return;
		hadammo = other.ammo_plasma;
		new = IT_PLASMAGUN;
		other.ammo_plasma = other.ammo_plasma + 30;
	}
	else if (self.classname == "weapon_shotgun")
	{
		if (leave && (other.items & IT_SHOTGUN) )
			return;
		hadammo = other.ammo_shells;
		new = IT_SHOTGUN;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else if (self.classname == "weapon_rocketlauncher")
	{
		if (leave && (other.items & IT_ROCKET_LAUNCHER) )
			return;
		hadammo = other.ammo_rockets;
		new = IT_ROCKET_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else if (self.classname == "weapon_grenadelauncher")
	{
		if (leave && (other.items & IT_GRENADE_LAUNCHER) )
			return;
		hadammo = other.ammo_rockets;
		new = IT_GRENADE_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else if (self.classname == "weapon_railgun")
	{
		if (leave && (other.items & IT_RAILGUN) )
			return;
		hadammo = other.ammo_slugs;
		new = IT_RAILGUN;
		other.ammo_slugs = other.ammo_slugs + 15;
	}
	else
		objerror ("weapon_touch: unknown classname");

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

// change to the weapon
	old = other.items;
	other.items = other.items | new;

	stemp = self;
	self = other;

	self.weapon = new;

	W_SetCurrentAmmo();

	self = stemp;

	if (leave)
		return;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch == 1)
		self.nextthink = time + 30;
	self.think = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_plasmagun =
{
	precache_model ("models/weapons/plasma.md3");
	setmodel (self, "models/weapons/plasma.md3");
	self.weapon = IT_PLASMAGUN;
	self.netname = "Plasmagun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
	precache_model ("models/weapons/grenade.md3");
	setmodel (self, "models/weapons/grenade.md3");
	self.weapon = 3;
	self.netname = "Grenade Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
	precache_model ("progs/g_rock2.mdl");
	setmodel (self, "progs/g_rock2.mdl");
	self.weapon = 3;
	self.netname = "Rocket Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_railgun =
{
	self.weapon = 3;
	self.netname = "Railgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
local entity	stemp;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

// shotgun
	if (self.weapon == 1)
	{
		if (other.ammo_shells >= 100)
			return;
		other.ammo_shells = other.ammo_shells + self.aflag;
	}

// plasmagun
	if (self.weapon == 1)
	{
		if (other.ammo_plasma >= 100)
			return;
		other.ammo_plasma = other.ammo_plasma + self.aflag;
	}

// rockets
	if (self.weapon == 3)
	{
		if (other.ammo_rockets >= 100)
			return;
		other.ammo_rockets = other.ammo_rockets + self.aflag;
	}

// railgun
	if (self.weapon == 4)
	{
		if (other.ammo_slugs >= 100)
			return;
		other.ammo_slugs = other.ammo_slugs + self.aflag;
	}

	bound_other_ammo ();

	sprint (other, self.netname);
	sprint (other, "\n");
// ammo touch sound
	sound (other, CHAN_ITEM, "items/ammo.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

// if changed current ammo, update it
	stemp = self;
	self = other;
	W_SetCurrentAmmo();
	self = stemp;

// setup for respawning
	self.model = string_null;
	self.solid = SOLID_NOT;
	self.nextthink = time + 3;
	self.think = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};




float WEAPON_BIG2 = 1;

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
	self.touch = ammo_touch;

	setmodel (self, "models/items/ammo.md3");
	self.aflag = 10;

	self.weapon = 1;
	self.netname = "Shells";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_plasma =
{
	self.touch = ammo_touch;

	setmodel (self, "models/items/ammo.md3");
	self.aflag = 25;

	self.weapon = 2;
	self.netname = "Plasma";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
	self.touch = ammo_touch;

	setmodel (self, "models/items/ammo.md3");
	self.aflag = 10;

	self.weapon = 1;
	self.netname = "Rockets";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_slugs =
{
	self.touch = ammo_touch;

	setmodel (self, "models/items/ammo.md3");
	self.aflag = 10;

	self.weapon = 1;
	self.netname = "Slugs";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};