
void() bubble_bob;

/*
==============================================================================

PLAYER

==============================================================================
*/

$cd data/models/players/
$origin 0 0 0
$base base
$skin ""

//
// standing
//
$frame stand1 stand2 stand3 stand4 stand5

//
// running
//
$frame run1 run2 run3 run4 run5

//
// pain
//
$frame pain1 pain2 pain3 pain4 pain5 pain6

//
// death
//
$frame die1 die2 die3 die4 die5 die6 die7 die8 die9 die10

//
// attacking
//
$frame shot1 shot2 shot3 shot4 shot5 shot6
$frame axe1 axe2 axe3 axe4

/*
==============================================================================
PLAYER
==============================================================================
*/

void() player_run;

void()	player_stand =[	$stand1,	player_stand	]
{
	self.weaponframe=0;
	if (self.velocity_x || self.velocity_y)
	{
		self.walkframe=0;
		player_run();
		return;
	}

	if (self.walkframe >= 5)
		self.walkframe = 0;

	self.frame = $stand1 + self.walkframe;
	self.walkframe = self.walkframe + 1;	
};

void()	player_run =[	$run1,	player_run	]
{
	self.weaponframe=0;
	if (!self.velocity_x && !self.velocity_y)
	{
		self.walkframe=0;
		player_stand();
		return;
	}

	if (self.walkframe == 6)
		self.walkframe = 0;
		
	self.frame = self.frame + self.walkframe;
	self.walkframe = self.walkframe + 1;
};


void()	player_shot1 =	[$shot1, player_shot2	] {
	self.weaponframe=1;
	self.effects = self.effects | EF_MUZZLEFLASH;
};
void()	player_shot2 =	[$shot2, player_shot3	] {self.weaponframe=2;};
void()	player_shot3 =	[$shot3, player_shot4	] {self.weaponframe=3;};
void()	player_shot4 =	[$shot4, player_shot5	] {self.weaponframe=4;};
void()	player_shot5 =	[$shot5, player_shot6	] {self.weaponframe=5;};
void()	player_shot6 =	[$shot6, player_run	] {self.weaponframe=6;};

void()	player_axe1 =	[$axe1, player_axe2	] {self.weaponframe=1;};
void()	player_axe2 =	[$axe2, player_axe3	] {self.weaponframe=2;};
void()	player_axe3 =	[$axe3, player_axe4	] {
	self.weaponframe=3;
	W_FireAxe();
};
void()	player_axe4 =	[$axe4, player_run	] {self.weaponframe=4;};

//============================================================================

void() player_plasma1   =[$shot1, player_plasma1  ] 
{
	self.effects = self.effects | EF_MUZZLEFLASH;

	if (!self.button0)
		{player_run ();return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 9)
		self.weaponframe = 1;
};

//============================================================================

void() player_slug   =[$shot1, player_slug  ] 
{
	self.effects = self.effects | EF_MUZZLEFLASH;

	if (!self.button0)
		{player_run ();return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 5)
		self.weaponframe = 1;
};

//============================================================================


void() player_rocket1   =[$shot1, player_rocket2  ] {
       self.weaponframe=1;
       self.effects = self.effects | EF_MUZZLEFLASH;
};
void() player_rocket2   =[$shot2, player_rocket3  ] {self.weaponframe=2;};
void() player_rocket3   =[$shot3, player_rocket4  ] {self.weaponframe=3;};
void() player_rocket4   =[$shot4, player_rocket5  ] {self.weaponframe=4;};
void() player_rocket5   =[$shot5, player_rocket6  ] {self.weaponframe=5;};
void() player_rocket6   =[$shot6, player_run  ] {self.weaponframe=6;};
void(float num_bubbles) DeathBubbles;

void() PainSound =
{
	if (self.health < 0)
		return;

	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "sounds/player/telefrag.wav", 1, ATTN_NONE);
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{
		sound (self, CHAN_VOICE, "sounds/player/burn.wav", 1, ATTN_NORM);
	}

	if (self.pain_finished > time)
	{
		self.axhitme = 0;
		return;
	}
	self.pain_finished = time + 0.5;

// don't make multiple pain sounds right after each other

	sound (self, CHAN_VOICE, "sounds/player/hurt.wav", 1, ATTN_NORM);
};

void()	player_pain1 =	[	$pain1,	player_pain2	] {PainSound();self.weaponframe=0;};
void()	player_pain2 =	[	$pain2,	player_pain3	] {};
void()	player_pain3 =	[	$pain3,	player_pain4	] {};
void()	player_pain4 =	[	$pain4,	player_pain5	] {};
void()	player_pain5 =	[	$pain5,	player_pain6	] {};
void()	player_pain6 =	[	$pain6,	player_run	] {};

void() player_pain =
{
	if (self.weaponframe)
		return;

	if (self.invisible_finished > time)
		return;		// eyes don't have pain frames

	player_pain1 ();
};

void() player_die1;

void() DeathBubblesSpawn =
{
local entity	bubble;
	if (self.owner.waterlevel != 3)
		return;
	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.owner.origin + '0 0 24');
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + 0.1;
	self.think = DeathBubblesSpawn;
	self.air_finished = self.air_finished + 1;
	if (self.air_finished >= self.bubble_count)
		remove(self);
};

void(float num_bubbles) DeathBubbles =
{
local entity	bubble_spawner;
	
	bubble_spawner = spawn();
	setorigin (bubble_spawner, self.origin);
	bubble_spawner.movetype = MOVETYPE_NONE;
	bubble_spawner.solid = SOLID_NOT;
	bubble_spawner.nextthink = time + 0.1;
	bubble_spawner.think = DeathBubblesSpawn;
	bubble_spawner.air_finished = 0;
	bubble_spawner.owner = self;
	bubble_spawner.bubble_count = num_bubbles;
	return;
};


void() DeathSound =
{
	sound (self, CHAN_VOICE, "sounds/player/die.wav", 1, ATTN_NONE);
	return;
};


void() PlayerDead =
{
	self.nextthink = -1;
// allow respawn after a certain time
	self.deadflag = DEAD_DEAD;
};

vector(float dm) VelocityForDamage =
{
	local vector v;

	v_x = 100 * crandom();
	v_y = 100 * crandom();
	v_z = 200 + 100 * random();

	if (dm > -50)
	{
//		dprint ("level 1\n");
		v = v * 0.7;
	}
	else if (dm > -200)
	{
//		dprint ("level 3\n");
		v = v * 2;
	}
	else
		v = v * 10;

	return v;
};

void(string gibname, float dm) ThrowGib =
{
	local	entity new;

	new = spawn();
	new.origin = self.origin;
	setmodel (new, gibname);
	setsize (new, '0 0 0', '0 0 0');
	new.velocity = VelocityForDamage (dm);
	new.movetype = MOVETYPE_BOUNCE;
	new.solid = SOLID_NOT;
	new.avelocity_x = random()*600;
	new.avelocity_y = random()*600;
	new.avelocity_z = random()*600;
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + 10 + random()*10;
	new.frame = 0;
	new.flags = 0;
};

void(string gibname, float dm) ThrowHead =
{
	setmodel (self, gibname);
	self.frame = 0;
	self.nextthink = -1;
	self.movetype = MOVETYPE_BOUNCE;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.view_ofs = '0 0 8';
	setsize (self, '-16 -16 0', '16 16 56');
	self.velocity = VelocityForDamage (dm);
	self.origin_z = self.origin_z - 24;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = crandom() * '0 600 0';
};


void() GibPlayer =
{
	ThrowHead ("progs/h_player.mdl", self.health);
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);

	self.deadflag = DEAD_DEAD;

	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "sounds/player/telefrag.wav", 1, ATTN_NONE);
		return;
	}

	if (damage_attacker.classname == "teledeath2")
	{
		sound (self, CHAN_VOICE, "sounds/player/telefrag.wav", 1, ATTN_NONE);
		return;
	}
		
	sound (self, CHAN_VOICE, "sounds/player/die.wav", 1, ATTN_NONE);
};

void() PlayerDie =
{
	self.items = self.items - (self.items & IT_INVISIBILITY);
	self.invisible_finished = 0;	// don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.modelindex = modelindex_player;	// don't use eyes

	self.weaponmodel="";
	self.view_ofs = '0 0 -8';
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_NOT;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	if (self.velocity_z < 10)
		self.velocity_z = self.velocity_z + random()*300;

	if (self.health < -40)
	{
		GibPlayer ();
		return;
	}

	DeathSound();
	
	self.angles_x = 0;
	self.angles_z = 0;
	
	player_die1();
};

void() set_suicide_frame =
{	// used by klill command and diconnect command
	if (self.model != "models/players/player.md3")
		return;	// allready gibbed
	self.frame = $die1;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_TOSS;
	self.deadflag = DEAD_DEAD;
	self.nextthink = -1;
};


void()	player_die1	= [	$die1,	player_die2] {};
void()	player_die2	= [	$die1,	player_die3] {};
void()	player_die3	= [	$die1,	player_die4] {};
void()	player_die4	= [	$die1,	player_die5] {};
void()	player_die5	= [	$die1,	player_die6] {};
void()	player_die6	= [	$die1,	player_die7] {};
void()	player_die7	= [	$die1,	player_die8] {};
void()	player_die8	= [	$die1,	player_die9] {};
void()	player_die9	= [	$die1,	player_die10] {};
void()	player_die10	= [	$die1,	player_die10] {PlayerDead();};