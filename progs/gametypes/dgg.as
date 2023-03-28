int prcYesIcon;
int[] currentWeapon(maxClients);

int weapon(int rank) {
    switch (rank) {
        case 0:
            return WEAP_ELECTROBOLT;
        case 1:
            return WEAP_ROCKETLAUNCHER;
        case 2:
            return WEAP_LASERGUN;
        case 3:
            return WEAP_PLASMAGUN;
        case 4:
            return WEAP_GRENADELAUNCHER;
        case 5:
            return WEAP_RIOTGUN;
        case 6:
            return WEAP_MACHINEGUN;
        case 7:
            return WEAP_GUNBLADE;
        case 8:
            return WEAP_INSTAGUN;
    }

    return WEAP_NONE;
}

int weaponIcon(int rank) {
    switch (rank) {
        case 0:
            return G_ImageIndex("gfx/hud/icons/weapon/electro");
        case 1:
            return G_ImageIndex("gfx/hud/icons/weapon/rocket");
        case 2:
            return G_ImageIndex("gfx/hud/icons/weapon/laser");
        case 3:
            return G_ImageIndex("gfx/hud/icons/weapon/plasma");
        case 4:
            return G_ImageIndex("gfx/hud/icons/weapon/grenade");
        case 5:
            return G_ImageIndex("gfx/hud/icons/weapon/riot");
        case 6:
            return G_ImageIndex("gfx/hud/icons/weapon/machinegun");
        case 7:
            return G_ImageIndex("gfx/hud/icons/weapon/gunblade_blast");
        case 8:
            return G_ImageIndex("gfx/hud/icons/weapon/instagun");
    }
    
    return G_ImageIndex("gfx/hud/icons/weapon/nogun_cross");
}

// a player has just died. The script is warned about it so it can account scores
void DM_playerKilled( Entity @target, Entity @attacker, Entity @inflictor )
{
    if ( match.getState() != MATCH_STATE_PLAYTIME )
        return;

    if ( @target.client == null )
        return;

    // Update player weapons
    if ( currentWeapon[target.playerNum] > 0 ) currentWeapon[target.playerNum]--; // Drop one weapon rank as a penalty
    
    if ( @attacker != null && @attacker.client != null ) {
        if ( attacker.client.getEnt().isGhosting() == false ) {
            attacker.client.inventoryClear();
            if (currentWeapon[attacker.playerNum] < 8) {
                currentWeapon[attacker.playerNum]++; // Gain one weapon rank as a reward
                attacker.client.inventoryGiveItem(weapon(currentWeapon[attacker.playerNum]));
                attacker.client.selectWeapon(weapon(currentWeapon[attacker.playerNum]));
            } else {
                // Kill with last weapon is +1 score
                attacker.client.stats.setScore(attacker.client.stats.score + 1);

                // Reset to first weapon
                currentWeapon[attacker.playerNum] = 0;
                attacker.client.inventoryGiveItem(weapon(0));
                attacker.client.selectWeapon(weapon(0));
            }
            
            attacker.client.inventorySetCount( AMMO_GUNBLADE, 1 ); // enable gunblade blast

            // These should get their values from cvars
            attacker.health = attacker.health + 15;
            attacker.client.armor = attacker.client.armor + 10;
        }
    }
    
    award_playerKilled(@target, @attacker, @inflictor);
}

bool GT_Command( Client @client, const String &cmdString, const String &argsString, int argc )
{
    if ( cmdString == "cvarinfo" )
    {
        GENERIC_CheatVarResponse( client, cmdString, argsString, argc );
        return true;
    }
    // example of registered command
    else if ( cmdString == "gametype" )
    {
        String response = "";
		Cvar fs_game( "fs_game", "", 0 );
		String manifest = gametype.manifest;

        response += "\n";
        response += "Gametype " + gametype.name + " : " + gametype.title + "\n";
        response += "----------------\n";
        response += "Version: " + gametype.version + "\n";
        response += "Author: " + gametype.author + "\n";
        response += "Mod: " + fs_game.string + (!manifest.empty() ? " (manifest: " + manifest + ")" : "") + "\n";
        response += "----------------\n";

        G_PrintMsg( client.getEnt(), response );
        return true;
    }

    return false;
}

// When this function is called the weights of items have been reset to their default values,
// this means, the weights *are set*, and what this function does is scaling them depending
// on the current bot status.
// Player, and non-item entities don't have any weight set. So they will be ignored by the bot
// unless a weight is assigned here.
bool GT_UpdateBotStatus( Entity @self )
{
    return GENERIC_UpdateBotStatus( self );
}

// select a spawning point for a player
Entity @GT_SelectSpawnPoint( Entity @self )
{
    return GENERIC_SelectBestRandomSpawnPoint( self, "info_player_deathmatch" );
}

String @GT_ScoreboardMessage(uint maxlen) {
	String scoreboardMessage = "";
	String entry;
	Team @team;
	Entity @ent;
	int i, weaponImage, readyIcon;

    @team = @G_GetTeam( TEAM_PLAYERS );

    // &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
    entry = "&t " + int( TEAM_PLAYERS ) + " " + team.stats.score + " 0 ";

    if(scoreboardMessage.len() + entry.len() < maxlen) {
        scoreboardMessage += entry;
    }

    for(i = 0; @team.ent(i) != null; i++) {
        @ent = @team.ent(i);

        readyIcon = ent.client.isReady() ? prcYesIcon : 0;
        if (!ent.isGhosting()) {
            weaponImage = currentWeapon[ent.playerNum] > 0 ? weaponIcon(currentWeapon[ent.playerNum]) : weaponIcon(0);
        } else {
            weaponImage = weaponIcon(-1);
        }

        int playerID = (ent.isGhosting() && (match.getState() == MATCH_STATE_PLAYTIME)) ? -(ent.playerNum + 1) : ent.playerNum;

        // "Name Clan Score Frags Ping W R"
        entry = "&p " + playerID + " "
            + ent.client.clanName + " "
            + ent.client.stats.score + " "
            + ent.client.stats.frags + " "
            + ent.client.ping + " "
            + weaponImage + " "
            + readyIcon + " ";
    

        if(scoreboardMessage.len() + entry.len() < maxlen) {
            scoreboardMessage += entry;
        }
    }

	return scoreboardMessage;
}

// Some game actions trigger score events. These are events not related to killing
// oponents, like capturing a flag
// Warning: client can be null
void GT_ScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( score_event == "dmg" )
    {
    }
    else if ( score_event == "kill" )
    {
        Entity @attacker = null;

        if ( @client != null )
            @attacker = @client.getEnt();

        int arg1 = args.getToken( 0 ).toInt();
        int arg2 = args.getToken( 1 ).toInt();

        // target, attacker, inflictor
        DM_playerKilled( G_GetEntity( arg1 ), attacker, G_GetEntity( arg2 ) );
    }
    else if ( score_event == "award" )
    {
    }
}

// a player is being respawned. This can happen from several ways, as dying, changing team,
// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
void GT_PlayerRespawn( Entity @ent, int old_team, int new_team )
{
    if ( ent.isGhosting() )
        return;

    Item @item;
    Item @ammoItem;

    // Give correct weapon according to kill row
    ent.client.inventoryClear();
    ent.client.inventorySetCount( AMMO_GUNBLADE, 1 ); // enable gunblade blast
    ent.client.inventoryGiveItem(weapon(currentWeapon[ent.playerNum]));
    ent.client.selectWeapon(weapon(currentWeapon[ent.playerNum]));

    ent.health = 20;
    ent.client.armor = 50;

    // add a teleportation effect
    ent.respawnEffect();
}

// Thinking function. Called each frame
void GT_ThinkRules()
{
    if ( match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished() )
        match.launchState( match.getState() + 1 );

    if ( match.getState() >= MATCH_STATE_POSTMATCH )
        return;

	GENERIC_Think();

    // check maxHealth rule
    for ( int i = 0; i < maxClients; i++ )
    {
        Entity @ent = @G_GetClient( i ).getEnt();
        if ( ent.client.state() >= CS_SPAWNED && ent.team != TEAM_SPECTATOR )
        {
            if ( ent.health > ent.maxHealth ) {
                ent.health -= ( frameTime * 0.001f );
				// fix possible rounding errors
				if( ent.health < ent.maxHealth ) {
					ent.health = ent.maxHealth;
				}
			}
        }
    }
}

// The game has detected the end of the match state, but it
// doesn't advance it before calling this function.
// This function must give permission to move into the next
// state by returning true.
bool GT_MatchStateFinished( int incomingMatchState )
{
    if ( match.getState() <= MATCH_STATE_WARMUP && incomingMatchState > MATCH_STATE_WARMUP
            && incomingMatchState < MATCH_STATE_POSTMATCH )
        match.startAutorecord();

    if ( match.getState() == MATCH_STATE_POSTMATCH )
        match.stopAutorecord();

    return true;
}

// the match state has just moved into a new state. Here is the
// place to set up the new state rules
void GT_MatchStateStarted()
{
    switch ( match.getState() )
    {
    case MATCH_STATE_WARMUP:
        gametype.pickableItemsMask = gametype.spawnableItemsMask;
        gametype.dropableItemsMask = gametype.spawnableItemsMask;
        GENERIC_SetUpWarmup();
		SpawnIndicators::Create( "info_player_deathmatch", TEAM_PLAYERS );
        break;

    case MATCH_STATE_COUNTDOWN:
        gametype.pickableItemsMask = 0; // disallow item pickup
        gametype.dropableItemsMask = 0; // disallow item drop
        GENERIC_SetUpCountdown();
		SpawnIndicators::Delete();
        break;

    case MATCH_STATE_PLAYTIME:
        gametype.pickableItemsMask = gametype.spawnableItemsMask;
        gametype.dropableItemsMask = gametype.spawnableItemsMask;
        GENERIC_SetUpMatch();
        break;

    case MATCH_STATE_POSTMATCH:
        gametype.pickableItemsMask = 0; // disallow item pickup
        gametype.dropableItemsMask = 0; // disallow item drop
        GENERIC_SetUpEndMatch();
        break;

    default:
        break;
    }
}

// the gametype is shutting down cause of a match restart or map change
void GT_Shutdown()
{
}

// The map entities have just been spawned. The level is initialized for
// playing, but nothing has yet started.
void GT_SpawnGametype()
{
}

// Important: This function is called before any entity is spawned, and
// spawning entities from it is forbidden. If you want to make any entity
// spawning at initialization do it in GT_SpawnGametype, which is called
// right after the map entities spawning.

void GT_InitGametype()
{
    gametype.title = "Gungame";
    gametype.version = "2.0";
    gametype.author = "decldev";

    // if the gametype doesn't have a config file, create it
    if ( !G_FileExists( "configs/server/gametypes/" + gametype.name + ".cfg" ) )
    {
        String config;

        // the config file doesn't exist or it's empty, create it
        config = "// '" + gametype.title + "' gametype configuration file\n"
                 + "// This config will be executed each time the gametype is started\n"
                 + "\n\n// map rotation\n"
                 + "set g_maplist \"wdm1 wdm2 wdm4 wdm5 wdm6 wdm7 wdm9 wdm10 wdm11 wdm12 wdm13 wdm14 wdm15 wdm16 wdm17\" // list of maps in automatic rotation\n"
                 + "set g_maprotation \"1\"   // 0 = same map, 1 = in order, 2 = random\n"
                 + "\n// game settings\n"
                 + "set g_scorelimit \"0\" // Scores are only gained with last weapon kills\n"
                 + "set g_timelimit \"10\"\n"
                 + "set g_warmup_timelimit \"1\"\n"
                 + "set g_match_extendedtime \"0\"\n"
                 + "set g_allow_falldamage \"1\"\n"
                 + "set g_allow_selfdamage \"0\"\n"
                 + "set g_allow_teamdamage \"1\"\n"
                 + "set g_allow_stun \"1\"\n"
                 + "set g_teams_maxplayers \"0\"\n"
                 + "set g_teams_allow_uneven \"0\"\n"
                 + "set g_countdown_time \"5\"\n"
                 + "set g_maxtimeouts \"3\" // -1 = unlimited\n"
                 + "\necho \"" + gametype.name + ".cfg executed\"\n";

        G_WriteFile( "configs/server/gametypes/" + gametype.name + ".cfg", config );
        G_Print( "Created default config file for '" + gametype.name + "'\n" );
        G_CmdExecute( "exec configs/server/gametypes/" + gametype.name + ".cfg silent" );
    }

    gametype.spawnableItemsMask = ( IT_AMMO | IT_ARMOR | IT_POWERUP | IT_HEALTH );
    gametype.spawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);

    gametype.respawnableItemsMask = gametype.spawnableItemsMask;
    gametype.dropableItemsMask = gametype.spawnableItemsMask;
    gametype.pickableItemsMask = gametype.spawnableItemsMask;

    gametype.isTeamBased = false;
    gametype.isRace = false;
    gametype.hasChallengersQueue = false;
    gametype.maxPlayersPerTeam = 0;

    gametype.ammoRespawn = 20;
    gametype.armorRespawn = 25;
    gametype.weaponRespawn = 5;
    gametype.healthRespawn = 25;
    gametype.powerupRespawn = 90;
    gametype.megahealthRespawn = 20;
    gametype.ultrahealthRespawn = 40;

    gametype.readyAnnouncementEnabled = false;
    gametype.scoreAnnouncementEnabled = false;
    gametype.countdownEnabled = false;
    gametype.mathAbortDisabled = false;
    gametype.shootingDisabled = false;
    gametype.infiniteAmmo = true;
    gametype.canForceModels = true;
    gametype.canShowMinimap = false;
    gametype.teamOnlyMinimap = false;

	gametype.mmCompatible = false;
	
    gametype.spawnpointRadius = 256;

    if ( gametype.isInstagib )
        gametype.spawnpointRadius *= 2;

    // precache images that can be used by the scoreboard
	prcYesIcon = G_ImageIndex("gfx/hud/icons/vsay/yes");

    // set spawnsystem type
    for ( int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++ )
        gametype.setTeamSpawnsystem(team, SPAWNSYSTEM_INSTANT, 0, 0, false);

    // define the scoreboard layout
    G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %i 52 %l 48 %p l1 %r l1");
    G_ConfigString(CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Frags Ping W R");

    // add commands
    G_RegisterCommand("gametype");

    G_Print("Gametype '" + gametype.title + "' initialized\n");
}
