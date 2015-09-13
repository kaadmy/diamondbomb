
void() InitBodyQue;


void() main =
{
	dprint ("main function\n");

// these are just commands the the prog compiler to copy these files

	precache_file ("progs.dat");
	precache_file ("gfx.wad");
	precache_file ("quake.rc");
	precache_file ("default.cfg");

	precache_file ("gfx/menu/background.tga");

	precache_file ("gfx/menu/loading.tga");

	precache_sound ("ui/click.wav");
	precache_sound ("ui/cancel.wav");
	precache_sound ("ui/increase.wav");
	precache_sound ("ui/decrease.wav");

	precache_file ("maps/start.bsp");
};


entity	lastspawn;

//=======================
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.
*/
//=======================
void() worldspawn =
{
	lastspawn = world;
	InitBodyQue ();

// map stuff
	cvar_set ("sv_gravity", "800");

// player precaches
	W_Precache ();			// get weapon precaches

// sounds used from C physics code
	precache_sound ("sounds/player/land.wav");		// landing thud

// setup precaches allways needed
	precache_sound ("sounds/items/respawn.wav");		// item respawn sound
	precache_sound ("sounds/player/jump.wav");		// player jump
	precache_sound ("sounds/player/land.wav");			// player landing

	precache_sound ("sounds/player/die.wav");		// telefrag
	precache_sound ("sounds/player/teleport.wav");		// teleport sound
	precache_sound ("sounds/items/ammo.wav");		// ammo pick up
	precache_sound ("sounds/items/weapon.wav");		// weapon up

	precache_sound ("sounds/items/armorshard.wav");		// armors
	precache_sound ("sounds/items/mediumarmor.wav");
	precache_sound ("sounds/items/megaarmor.wav");
	precache_model ("models/items/armorshard.md3");
	precache_model ("models/items/mediumarmor.md3");
	precache_model ("models/items/megaarmor.md3");

	precache_sound ("sounds/items/minihealth.wav");		// healths
	precache_sound ("sounds/items/mediumhealth.wav");
	precache_sound ("sounds/items/megahealth.wav");
	precache_model ("models/items/minihealth.md3");
	precache_model ("models/items/mediumhealth.md3");
	precache_model ("models/items/megahealth.md3");

// player sounds
	precache_sound ("sounds/player/hurt.wav");		// hurt
	precache_sound ("sounds/player/die.wav");		// death
	precache_sound ("sounds/player/burn.wav");		// player in lava sounds

// player model
	precache_model ("models/players/player.md3");

// weapon models
	precache_model ("models/weapons/shotgun.md3");
	precache_model ("models/weapons/plasmagun.md3");
	precache_model ("models/weapons/railgun.md3");
	precache_model ("models/weapons/rocketlauncher.md3");
	precache_model ("models/weapons/grenadelauncher.md3");

	precache_model ("models/items/ammo.md3");

//
// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
//

/* DISABLED
	// 0 normal
	lightstyle(0, "m");

	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");

	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 FAST STROBE
	lightstyle(4, "mamamamamama");

	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");

	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");

	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the light program for switchable lights

	// 63 testing
	lightstyle(63, "a");
*/
};

void() StartFrame =
{
	teamplay = cvar("teamplay");
	skill = cvar("skill");
	framecount = framecount + 1;

	if (!deathmatch)
		localcmd("deathmatch 1;coop 0;restart\n");
};

/*
==============================================================================

BODY QUE

==============================================================================
*/

entity	bodyque_head;

void() bodyque =
{	// just here so spawn functions don't complain after the world
	// creates bodyques
};

void() InitBodyQue =
{
	local entity	e;

	bodyque_head = spawn();
	bodyque_head.classname = "bodyque";
	bodyque_head.owner = spawn();
	bodyque_head.owner.classname = "bodyque";
	bodyque_head.owner.owner = spawn();
	bodyque_head.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner = bodyque_head;
};

// make a body que entry for the given ent so the ent can be
// respawned elsewhere
void(entity ent) CopyToBodyQue =
{
	bodyque_head.angles = ent.angles;
	bodyque_head.model = ent.model;
	bodyque_head.modelindex = ent.modelindex;
	bodyque_head.frame = ent.frame;
	bodyque_head.colormap = ent.colormap;
	bodyque_head.movetype = ent.movetype;
	bodyque_head.velocity = ent.velocity;
	bodyque_head.flags = 0;
	setorigin (bodyque_head, ent.origin);
	setsize (bodyque_head, ent.mins, ent.maxs);
	bodyque_head = bodyque_head.owner;
};