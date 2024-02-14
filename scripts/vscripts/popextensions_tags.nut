local classes = ["", "scout", "sniper", "soldier", "demo", "medic", "heavy", "pyro", "spy", "engineer"] //make element 0 a dummy string instead of doing array + 1 everywhere

// it's a table cuz much faster
local validProjectiles =
{
	tf_projectile_arrow				= 1
	tf_projectile_energy_ball		= 1 // Cow Mangler
	tf_projectile_healing_bolt		= 1 // Crusader's Crossbow, Rescue Ranger
	tf_projectile_lightningorb		= 1 // Lightning Orb Spell
	tf_projectile_mechanicalarmorb	= 1 // Short Circuit
	tf_projectile_rocket			= 1
	tf_projectile_sentryrocket		= 1
	tf_projectile_spellfireball		= 1
	tf_projectile_energy_ring		= 1 // Bison
	tf_projectile_flare				= 1
}


//behavior tags
local popext_funcs =
{
    popext_addcond = function(bot, args)
    {
        printl(args[0])
        if (args.len() == 1)
            if (args[0].tointeger() == 43)
                bot.ForceChangeTeam(2, false)
            else 
                bot.AddCond(args[0].tointeger())
                
        else if (args.len() >= 2)
            bot.AddCondEx(args[0].tointeger(), args[1].tointeger(), null)
    }

    popext_reprogrammed = function(bot, args)
    {
        bot.ForceChangeTeam(2, false)
    }

    popext_reprogrammed_neutral = function(bot, args)
    {
        bot.ForceChangeTeam(0, false)
    }

    popext_altfire = function(bot, args)
    {
        if (args.len() == 1)
            bot.PressAltFireButton(99999)
        else if (args.len() >= 2)
            bot.PressAltFireButton(args[1].tointeger())
    }

    popext_usehumanmodel = function(bot, args)
    {
        bot.SetCustomModelWithClassAnimations(format("models/player/%s.mdl", classes[bot.GetPlayerClass()]))
    }

    popext_alwaysglow = function(bot, args)
    {
        NetProps.SetPropBool(bot, "m_bGlowEnabled", true)
    }

    popext_stripslot = function(bot, args)
    {
        if (args.len() == 1) args.append(-1)
        local slot = args[1].tointeger()

        if (slot == -1) slot = player.GetActiveWeapon().GetSlot()

        for (local i = 0; i < SLOT_COUNT; i++)
        {
            local weapon = GetWeaponInSlot(player, i)
    
            if (weapon == null || weapon.GetSlot() != slot) continue
    
            weapon.Destroy()
            break
        }
    }

    popext_fireweapon = function(bot, args)
    {
        //think function
        function FireWeaponThink(bot)
        {

        }
    }

    //this is a very simple method for giving bots weapons. 
    popext_giveweapon = function(bot, args)
    {
        local weapon = Entities.CreateByClassname(args[0])
        NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", args[1].tointeger())
        NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
        NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
        weapon.SetTeam(bot.GetTeam())
        Entities.DispatchSpawn(weapon)
        
        bot.Weapon_Equip(weapon)
        
        for (local i = 0; i < 7; i++)
        {
            local heldWeapon = NetProps.GetPropEntityArray(bot, "m_hMyWeapons", i)
            if (heldWeapon == null)
                continue
            if (heldWeapon.GetSlot() != weapon.GetSlot())
                continue
            heldWeapon.Destroy()
            NetProps.SetPropEntityArray(bot, "m_hMyWeapons", weapon, i)
            break
        }
    
        return weapon
    }

    popext_usebestweapon = function(bot, args)
    {
        function BestWeaponThink(bot)
        {
            switch(bot.GetPlayerClass())
            {
            case 1: //TF_CLASS_SCOUT

                //scout and pyro's UseBestWeapon is inverted
                //switch them to secondaries, then back to primary when enemies are close
                if (bot.GetActiveWeapon() != NetProps.GetPropEntityArray(bot, "m_hMyWeapons", 1))
                    bot.Weapon_Switch(NetProps.GetPropEntityArray(bot, "m_hMyWeapons", 1))

                for (local p; p = Entities.FindByClassnameWithin(p, "player", bot.GetOrigin(), 500);)
                {
                    if (p.GetTeam() == bot.GetTeam()) continue
                    local primary;
                    
                    for (local i = 0; i < 7; i++)
                    {
                        local wep = NetProps.GetPropEntityArray(bot, "m_hMyWeapons", i)
                        if ( wep == null || wep.GetSlot() != 0) continue

                        primary = wep
                        break
                    }
                    bot.Weapon_Switch(primary)
                    primary.AddAttribute("disable weapon switch", 1, 1)
                    primary.ReapplyProvision()
                }
                break

            case 2: //TF_CLASS_SNIPER
                for (local p; p = Entities.FindByClassnameWithin(p, "player", bot.GetOrigin(), 750);)
                {
                    if (p.GetTeam() == bot.GetTeam() || bot.GetActiveWeapon().GetSlot() == 2) continue //potentially not break sniper ai
                    local secondary;
                    
                    for (local i = 0; i < 7; i++)
                    {
                        local wep = NetProps.GetPropEntityArray(bot, "m_hMyWeapons", i)
                        if ( wep == null || wep.GetSlot() != 1) continue

                        secondary = wep
                        break
                    }

                    bot.Weapon_Switch(secondary)
                    secondary.AddAttribute("disable weapon switch", 1, 1)
                    secondary.ReapplyProvision()
                }
                break
            
            case 3: //TF_CLASS_SOLDIER
                for (local p; p = Entities.FindByClassnameWithin(p, "player", bot.GetOrigin(), 500);)
                {
                    if (p.GetTeam() == bot.GetTeam() || bot.GetActiveWeapon().Clip1() != 0) continue
                   
                    local secondary;
                    
                    for (local i = 0; i < 7; i++)
                    {
                        local wep = NetProps.GetPropEntityArray(bot, "m_hMyWeapons", i)
                        if ( wep == null || wep.GetSlot() != 1) continue

                        secondary = wep
                        break
                    }
                    bot.Weapon_Switch(secondary)

                    secondary.AddAttribute("disable weapon switch", 1, 2)
                    secondary.ReapplyProvision()
                }
                break
            
            case 7: //TF_CLASS_PYRO
            
                //scout and pyro's UseBestWeapon is inverted
                //switch them to secondaries, then back to primary when enemies are close
                //TODO: check if we're targetting a soldier with a simple raycaster, or wait for more bot functions to be exposed
                if (bot.GetActiveWeapon() != NetProps.GetPropEntityArray(bot, "m_hMyWeapons", 1))
                    bot.Weapon_Switch(NetProps.GetPropEntityArray(bot, "m_hMyWeapons", 1))

                for (local p; p = Entities.FindByClassnameWithin(p, "player", bot.GetOrigin(), 500);)
                {
                    if (p.GetTeam() == bot.GetTeam()) continue
                    local primary;
                    
                    for (local i = 0; i < 7; i++)
                    {
                        local wep = NetProps.GetPropEntityArray(bot, "m_hMyWeapons", i)
                        if ( wep == null || wep.GetSlot() != 0) continue

                        primary = wep
                        break
                    }
                    bot.Weapon_Switch(primary)
                    primary.AddAttribute("disable weapon switch", 1, 1)
                    primary.ReapplyProvision()
                }
                break
            }
        }
        bot.GetScriptScope().thinktable.BestWeaponThink <- BestWeaponThink
    }
}

// ::GetBotBehaviorFromTags <- function(bot) 
// {
//     local tags = {}
//     local scope = bot.GetScriptScope()
//     bot.GetAllBotTags(tags)
    
//     if (tags.len() == 0) return
    
//     foreach (tag in tags) 
//     {
//         local args = split(tag, "|")
//         if (args.len() == 0) continue
//         local func = args.remove(0)
//         if (func in popext_funcs)
//             popext_funcs[func](bot, args)
//     }
    // function PopExt_BotThinks()
    // {
    //     local scope = self.GetScriptScope()
    //     if (scope.thinktable.len() < 1) return;

    //     foreach (_, func in scope.thinktable)
    //        func(self)
    // }
//     AddThinkToEnt(bot, "PopExt_BotThinks")
// }

local tagtest = "popext_usebestweapon"
::GetBotBehaviorFromTags <- function(bot)
{
    if (bot.HasBotTag(tagtest))
    {
        local args = split(tagtest, "|")
        local func = args.remove(0)
        // printl(popext_funcs[func] + " : " + bot + " : " + args[1])
        if (func in popext_funcs)
            popext_funcs[func](bot, args)
    }
    function PopExt_BotThinks()
    {
        local scope = self.GetScriptScope()
        if (scope.thinktable.len() < 1) return;

        foreach (_, func in scope.thinktable)
           func(self)
        return -1
    }
    AddThinkToEnt(bot, "PopExt_BotThinks")
}

::PopExt_Tags <- {

    function OnGameEvent_post_inventory_application(params) 
    {
        local bot = GetPlayerFromUserID(params.userid)
        if (!bot.IsBotOfType(1337)) return

        local thinktable = {}
        bot.ValidateScriptScope()
        bot.GetScriptScope().thinktable <- thinktable
        EntFireByHandle(bot, "RunScriptCode", "GetBotBehaviorFromTags(self)", -1, null, null);
    }

    function OnGameEvent_player_builtobject(params) 
    {
        local bot = GetPlayerFromUserID(params.userid)
        if (!bot.IsBotOfType(1337)) return

        local building = EntIndexToHScript(params.entindex)
        if ((bot.HasBotTag("popext_dispenserasteleporter") && params.object == 1) || (bot.HasBotTag("popext_dispenserassentry") && params.object == 2))
        {
            local dispenser = SpawnEntityFromTable("obj_dispenser", {
                targetname = "dispenserasteleporter"+params.index,
                defaultupgrade = 3,
                origin = building.GetOrigin()
            })
            NetProps.SetPropEntity(dispenser, "m_hBuilder", bot)
            dispenser.SetOwner(bot)
            building.Kill()
        }
    }

    function OnGameEvent_player_team(params)
    {
        local bot = GetPlayerFromUserID(params.userid)
        if (bot.IsBotOfType(1337) || params.team == 1)
            AddThinkToEnt(bot, null)
    }

    function OnGameEvent_player_death(params)
    {
        local bot = GetPlayerFromUserID(params.userid)
        if (bot.IsBotOfType(1337) || params.team == 1)
            AddThinkToEnt(bot, null)
    }
}
__CollectGameEventCallbacks(PopExt_Tags)