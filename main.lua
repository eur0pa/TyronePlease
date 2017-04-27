--[[
    thanks to "Loli" for Mei's clean code!
    it's been a meaningful resource
--]]

-- register the mod
local mod = RegisterMod("Tyrone", 1)

-- mod ids for easier access
local itemId = Isaac.GetItemIdByName("Nicalis Curse")
local costume_srs = Isaac.GetCostumeIdByPath("gfx/characters/tyrone_is_srs.anm2")
local costume_scheming = Isaac.GetCostumeIdByPath("gfx/characters/tyrone_is_scheming.anm2")

--[[
     collectible tracking for good / bad synergies
--]]
local hasTyrone = false
local hasBrimstone = false
local hasProptosis = false
local hasWhoreOfBabylon = false
local hasTheBody = false
local hasPlacenta = false
local hasLordOfThePit = false
local hasThunderThighs = false
local hasSacredHeart = false
local hasGodHead = false
local hasEvesMascara = false
local hasIsaacsHeart = false
local hasPunchingBag = false
local hasBloodyLust = false
local hasAbaddon = false
local hasProptosis = false
local hasNumberOne = false
local hasMonstrosLung = false
local hasCursedEye = false
local hasFireMind = false
local hasCricketsBody = false
local hasEpicFetus = false
local hasTheWiz = false
local hasDrFetus = false
local hasRubberCement = false
local hasSoyMilk = false
local hasMarked = false
local hasPenetrativeTears = false
local hasGhostTears = false
local hasSpeedBall = false
local hasBucketOfLard = false
local hasLostContact = false
local hasPolyphemus = false
local hasSkeletonKey = false
local hasPayToPlay = false
local hasMomsKnife = false
local hasTinyPlanet = false
local hasSadBombs = false
local hasScatterBombs = false
local hasBomberBoy = false
local hasJudasShadow = false
local hasFullHP = false
local hasTranscendence = false
local hasGuillotine = false
local hasIpecac = false
local hasMyReflection = false
local hasChocolateMilk = false
local hasKidneyStone = false
local hasSacrificialDagger = false
local hasBrokenWatch = false
local hasNumberTwo = false
local has8InchNails = false
local hasPisces = false
local hasTheD6 = false
local hasLumpOfCoal = false
local hasMagicMushroom = false
local hasLibra = false
local hasLeo = false
local hasTheNail = false
local hasNotchedAxe = false
local hasMineCrafter = false
local hasSulfuricAcid = false
local hasMamaMega = false
local hasSamsonsChain = false
local hasHagalaz = false
local collectibleCount = 0

--[[
    internals
--]]
local _log = {}
local game = Game()             -- game instance
local player = nil              -- player instance
local costumeEquipped = false   -- player has goatee
local floor = 0
local room = nil                -- store the current room
local oldRoom = nil             -- store the previous room
local roomEntities = nil        -- entity list per room
local tyrone = nil              -- fuck shit up
local tyRooms = {}              -- rooms we fucked with
local tyroneHasPressedTheButton = false
local updateCostume = false
local ruinedYet = false
local noticedYet = false
local karma = 0
local canFly = false            -- can we fly?
local punchingBagEntity = nil
local dropSeed = nil
local spawnSeed = nil
local tyroneSeed = nil
local roomHazards = false


--[[
    local RNG() implementation by Loli
--]]
local modRNG = RNG()
local function random(min, max)
    if min ~= nil and max ~= nil then
        -- [x,y]
        return math.floor(modRNG:RandomFloat() * (max - min + 1) + min)
    elseif min ~= nil then
        -- [0,x]
        return math.floor(modRNG:RandomFloat() * (min + 1))
    end
    -- [0,1)
    return modRNG:RandomFloat()
end


--[[
    entity utilities by Loli:
        - CompareEntity(a, b)
          checks to make sure the entity being referenced is the right one.
          if the type, variant, subtype and index are al the same, the entity
          should be the one we're looking for
        - FindEntity(entity)
          uses CompareEntity() to find an entity
        - HasParent(entity, parent)
          loops through all parents to check if an entity is an ancestor
          to another entity
--]]
local function CompareEntity(a, b, relaxed)
    relaxed = relaxed or false
    if a and b then
        if not relaxed then
            return a.Type == b.Type and
                   a.Variant == b.Variant and
                   a.SubType == b.SubType and
                   a.Index == b.Index
        else
            return a.Type == b
        end
    else
        return false
    end
end

local function FindEntity(entityLike, relaxed)
    relaxed = relaxed or false
    local entities = Isaac.GetRoomEntities()
    for i,entity in ipairs(entities) do
        if CompareEntity(entity, entityLike, relaxed) then
            return entity
        end
    end
end

local function HasParent(entity, parent)
    while entity ~= nil and
        not CompareEntity(entity, parent) and
        not CompareEntity(entity, entity) do
        if entity.Parent ~= nil and
            CompareEntity(entity.Parent, parent) then
            return true
        end
        entity = entity.Parent
    end
    return false
end


--[[
    log-mod by KubeRoot
--]]
function log(...)
    local args = {...}

    for _, v in ipairs(args) do
        table.insert(_log, tostring(v))
    end
end


--[[
    fuck shit up
--]]
local function Tyronize()
    local tyrone = {}
    local frame = game:GetFrameCount()

    --[[
        is tyrone going to press the button?

            - get room's spawn seed
            - xor it with room's drop seed
            - if modulo 5, tyrone has pressed the button
            - the button stays pressed as long as necessary
            - the button gets reset once spent
    --]]
    function tyrone.Please()
        tyroneSeed = spawnSeed ~ dropSeed
        return tyroneSeed % 5 == 0
    end

    --[[
        senpai cares for you!
        gives good synergies, but the button expires if the player
        isn't able to take advantage of any in the very room the
        button has been pressed

        todo: more good synergies for Tyrone-senpai to give out
    --]]
    function tyrone.NoticeMe()
        local karma = dropSeed % math.floor(random(2) + math.max(1, player.Luck))

        if karma == 1 then
            if hasBrimstone and not hasLumpOfCoal then
                player:AddCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL, 0, false)
                return true
            end

        elseif karma == 2 then
            if hasWhoreOfBabylon and not hasAbaddon then
                player:AddCollectible(CollectibleType.COLLECTIBLE_ABADDON, 0, false)
            end
        end

        return false
    end

    --[[
        ruin the game in creative ways
        if Tyrone can't ruin anything when evoked, the button _will not_
        expire until something has been ruined. karma is rolled to N + 1
        effects + player luck, giving a chance for nothing to happen.

        todo:
            + add tinted rocks grid entities when the player has no bombs
            + drop bombs outside of a curse room if said curse room has a
              red chest amidst four blue fires
            + add a chance for a left hand trinket swap after killing isaac
              on the cathedral
            + add a chance for a jera swap when holding blank card
            + more
    --]]
    function tyrone.RuinGame()
        local karma = dropSeed % math.floor(random(4) + math.max(1, player.Luck))
        _log[3] = "Bad Karma is " .. karma

        if karma == 1 then
            -- discharge actives if fully charged
            if player:GetActiveCharge() > 0 then
                player:SetActiveCharge(player:GetActiveCharge() - 2)
                return true
            end

        elseif karma == 2 then
            -- remove fly if hazards are in the room
            -- restore flying after leaving the room
            if canFly and roomHazards and room:IsFirstVisit() then
                player.CanFly = false
            elseif canFly ~= player.CanFly and not room:IsFirstVisit() then
                player.CanFly = canFly
            end

        elseif karma == 3 then
            -- spawn a gravity well if the player is in a dice room
            if room:GetType() == RoomType.ROOM_DICE then
                if FindEntity(EntityType.ENTITY_PITFALL, true) then
                    return true
                end
                -- spawn a suction pitfall if none is present
                Isaac.Spawn(EntityType.ENTITY_PITFALL, 1, 0, room:GetCenterPos(), Vector(0,0), nil)
            end

        elseif karma == 4 then
            -- spawn tinted rocks if the player has no bombs
            return true
        end

        return false
    end

    --[[
        ruin good synergies
        as per RuinGame(), the button will not expire unless Tyrone has ruined
        one of your synergies

        todo:
            . fix scapegoat's AI to follow isaac's heart instead
    --]]
    function tyrone.RuinSynergies()
        -- brimstone + proptosis
        if hasBrimstone and not hasProptosis then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS, 0, false)
            return true
        end

        -- whore of babylon + a bunch of red hearts + hp regen
        if hasWhoreOfBabylon then
            if not hasTheBody then
                player:AddCollectible(CollectibleType.COLLECTIBLE_BODY, 0, false)
            end
            if not hasPlacenta then
                player:AddCollectible(CollectibleType.COLLECTIBLE_PLACENTA, 0, false)
            end
            return true
        end

        -- lord of the pit + speed down and exploding rocks / mushrooms
        if hasLordOfThePit and not hasThunderThighs then
            player:AddCollectible(CollectibleType.COLLECTIBLE_THUNDER_THIGHS, 0, false)
            return true
        end

        -- godhead + eve's mascara huge tear / shot speed down
        if (hasSacredHeart or hasGodHead) and not hasEvesMascara then
            player:AddCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA, 0, false)
            return true
        end

        -- isaac's heart + punching bag as a parent
        if hasIsaacsHeart and not hasPunchingBag then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PUNCHING_BAG, 0, false)
            return true
        end

        -- bloody lust + no red hearts
        if hasBloodyLust and not hasAbaddon then
            player:AddCollectible(CollectibleType.COLLECTIBLE_ABADDON, 0, false)
            return true
        end

        -- proptosis (only) + number one
        if hasProptosis and not hasNumberOne and not hasBrimstone then
            player:AddCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE, 0, false)
            return true
        end

        -- monstro's lung + cursed eye
        if hasMonstrosLung and not hasCursedEye then
            player:AddCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE, 0, false)
            return true
        end

        -- fire mind + splash damage and split shots
        if hasFireMind and not hasCricketsBody then
            player:AddCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY, 0, false)
            return true
        end

        -- uncontrollable epic fetus
        if hasEpicFetus and not hasTheWiz then
            player:AddCollectible(CollectibleType.COLLECTIBLE_THE_WIZ, 0, false)
            return true
        end

        -- "press 'R' to restart" dr fetus
        if hasDrFetus then
            if not hasTheWiz then
                player:AddCollectible(CollectibleType.COLLECTIBLE_THE_WIZ, 0, false)
            end
            if not hasTinyPlanet then
                player:AddCollectible(CollectibleType.COLLECTIBLE_TINY_PLANET, 0, false)
            end
            return true
        end

        -- soy milk + solid tears + marked
        if hasSoyMilk then
            if not hasMarked then
                player:AddCollectible(CollectibleType.COLLECTIBLE_MARKED, 0, false)
            end
            if hasPenetrativeTears then
                player.TearFlags = player.Tearflags ~ TearFlags.FLAG_PIERCING
            end
            if hasGhostTears then
                player.TearFlags = player.Tearflags ~ TearFlags.FLAG_SPECTRAL
            end
            return true
        end

        -- speed up + speed down
        if hasSpeedBall and not hasBucketOfLard then
            player:AddCollectible(CollectibleType.COLLECTIBLE_BUCKET_LARD, 0, false)
            return true
        end

        -- lost contact + tears down
        if hasLostContact and not hasPolyphemus then
            player:AddCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS, 0, false)
            return true
        end

        -- skeleton key + no more need for keys
        if hasSkeletonKey and not hasPayToPlay then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY, 0, false)
            return true
        end

        -- mom's knife + tiny planet
        if hasMomsKnife and not hasTinyPlanet then
            player:AddCollectible(CollectibleType.COLLECTIBLE_TINY_PLANET, 0, false)
            return true
        end

        -- "watch out for your own bombs" bombs
        if hasSadBombs then
            if not hasScatterBombs then
                player:AddCollectible(CollectibleType.COLLECTIBLE_SCATTER_BOMBS, 0, false)
            end
            if not hasBomberBoy then
                player:AddCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY, 0, false)
            end
            return true
        end

        -- judas' shadow + crapload of hp
        if hasJudasShadow then
            if not hasTheBody then
                player:AddCollectible(CollectibleType.COLLECTIBLE_BODY, 0, false)
            end
            if not hasFullHP then
                player:SetFullHearts()
            end
            return true
        end

        -- transcendence + guillotine
        if hasTranscendence and not hasGuillotine then
            player:AddCollectible(CollectibleType.COLLECTIBLE_GUILLOTINE, 0, false)
            return true
        end

        -- ipecac + my reflection
        if hasIpecac and not hasMyReflection then
            player:AddCollectible(CollectibleType.COLLECTIBLE_MY_REFLECTION, 0, false)
            return true
        end

        -- chocolate milk + kidney stone
        if hasChocolateMilk and not hasKidneyStone then
            player:AddCollectible(CollectibleType.COLLECTIBLE_KIDNEY_STONE, 0, false)
            return true
        end

        -- sacrificial dagger + broken watch
        if hasSacrificialDagger and not hasBrokenWatch then
            player:AddCollectible(CollectibleType.COLLECTIBLE_BROKEN_WATCH, 0, false)
            return true
        end

        -- extremely dangerous number two
        if hasNumberTwo and not hasBomberBoy then
            player:AddCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY, 0, false)
            return true
        end

        -- extreme pushback
        if has8InchNails and not hasPisces then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PISCES, 0, false)
            return true
        end

        -- annoying libra
        if hasMagicMushroom and not hasLibra then
            player:AddCollectible(CollectibleType.COLLECTIBLE_LIBRA, 0, false)
            return true
        end

        return false
    end

    --[[
        returns if there are any hazards in the current room. currently
        checks for red poops, spikes, creep and pitfalls
    --]]
    function tyrone.CheckForHazards()
        for i=0,room:GetGridSize() do
            local ent = room:GetGridEntity(i)
            if ent ~= nil then
                -- red poop
                if ent:ToPoop() ~= nil then
                    if ent:GetVariant() == 1 then
                        return true
                    end
                -- spikes
                elseif ent:ToSpikes() ~= nil then
                    return true
                end
            end
        end

        -- check for creep, player's is excluded
        for i,entity in ipairs(roomEntities) do
            if entity:ToEffect() ~= nil then
                if entity.Variant == EffectVariant.CREEP_GREEN or
                   entity.Variant == EffectVariant.CREEP_RED or
                   entity.Variant == EffectVariant.CREEP_YELLOW then
                    return true
                end
            elseif entity:ToNPC() ~= nil then
                if entity.Type == EntityType.ENTITY_PITFALL then
                    return true
                end
            end
        end

        return false
    end


    --[[
        keep track whether the player holds any of the collectibles
        we need
    --]]
    function tyrone.CheckOutMyStuff()
        hasBrimstone = player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
        hasWhoreOfBabylon = player:HasCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
        hasTheBody = player:HasCollectible(CollectibleType.COLLECTIBLE_BODY)
        hasPlacenta = player:HasCollectible(CollectibleType.COLLECTIBLE_PLACENTA)
        hasLordOfThePit = player:HasCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT)
        hasThunderThighs = player:HasCollectible(CollectibleType.COLLECTIBLE_THUNDER_THIGHS)
        hasSacredHeart = player:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART)
        hasGodHead = player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD)
        hasEvesMascara = player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA)
        hasIsaacsHeart = player:HasCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART)
        hasPunchingBag = player:HasCollectible(CollectibleType.COLLECTIBLE_PUNCHING_BAG)
        hasBloodyLust = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOODY_LUST)
        hasAbaddon = player:HasCollectible(CollectibleType.COLLECTIBLE_ABADDON)
        hasProptosis = player:HasCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS)
        hasNumberOne = player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE)
        hasMonstrosLung = player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG)
        hasCursedEye = player:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE)
        hasFireMind = player:HasCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND)
        hasCricketsBody = player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY)
        hasEpicFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)
        hasTheWiz = player:HasCollectible(CollectibleType.COLLECTIBLE_THE_WIZ)
        hasDrFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)
        hasRubberCement = player:HasCollectible(CollectibleType.COLLECTIBLE_RUBBER_CEMENT)
        hasSoyMilk = player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK)
        hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
        hasPenetrativeTears = false --player.TearFlags & TearFlags.FLAG_PIERCING
        hasGhostTears = false --player.TearFlags & TearFlags.FLAG_SPECTRAL
        hasSpeedBall = player:HasCollectible(CollectibleType.COLLECTIBLE_SPEED_BALL)
        hasBucketOfLard = player:HasCollectible(CollectibleType.COLLECTIBLE_BUCKET_LARD)
        hasLostContact = player:HasCollectible(CollectibleType.COLLECTIBLE_LOST_CONTACT)
        hasPolyphemus = player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS)
        hasSkeletonKey = player:HasCollectible(CollectibleType.COLLECTIBLE_SKELETON_KEY)
        hasPayToPlay = player:HasCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY)
        hasMomsKnife = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE)
        hasTinyPlanet = player:HasCollectible(CollectibleType.COLLECTIBLE_TINY_PLANET)
        hasSadBombs = player:HasCollectible(CollectibleType.COLLECTIBLE_SAD_BOMBS)
        hasScatterBombs = player:HasCollectible(CollectibleType.COLLECTIBLE_SCATTER_BOMBS)
        hasBomberBoy = player:HasCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY)
        hasJudasShadow = player:HasCollectible(CollectibleType.COLLECTIBLE_JUDAS_SHADOW)
        hasFullHP = player:HasFullHearts() or player:HasFullHeartsAndSoulHearts()
        hasTranscendence = player:HasCollectible(CollectibleType.COLLECTIBLE_TRANSCENDENCE)
        hasGuillotine = player:HasCollectible(CollectibleType.COLLECTIBLE_GUILLOTINE)
        hasIpecac = player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC)
        hasMyReflection = player:HasCollectible(CollectibleType.COLLECTIBLE_MY_REFLECTION)
        hasChocolateMilk = player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK)
        hasKidneyStone = player:HasCollectible(CollectibleType.COLLECTIBLE_KIDNEY_STONE)
        hasSacrificialDagger = player:HasCollectible(CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER)
        hasBrokenWatch = player:HasCollectible(CollectibleType.COLLECTIBLE_BROKEN_WATCH)
        hasNumberTwo = player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_TWO)
        has8InchNails = player:HasCollectible(CollectibleType.COLLECTIBLE_8_INCH_NAILS)
        hasPisces = player:HasCollectible(CollectibleType.COLLECTIBLE_PISCES)
        hasTheD6 = player:HasCollectible(CollectibleType.COLLECTIBLE_D6)
        hasLumpOfCoal = player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
        hasMagicMushroom = player:HasCollectible(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM)
        hasLibra = player:HasCollectible(CollectibleType.COLLECTIBLE_LIBRA)
        hasLeo = player:HasCollectible(CollectibleType.COLLECTIBLE_LEO)
        hasTheNail = player:HasCollectible(CollectibleType.COLLECTIBLE_THE_NAIL)
        hasNotchedAxe = player:HasCollectible(CollectibleType.COLLECTIBLE_NOTCHED_AXE)
        hasMineCrafter = player:HasCollectible(CollectibleType.COLLECTIBLE_MINE_CRAFTER)
        hasSulfuricAcid = player:HasCollectible(CollectibleType.COLLECTIBLE_SULFURIC_ACID)
        hasMamaMega = player:HasCollectible(CollectibleType.COLLECTIBLE_MAMA_MEGA)
        hasSamsonsChain = player:HasCollectible(CollectibleType.COLLECTIBLE_SAMSONS_CHAINS)
        hasHagalaz = (player:GetCard(0) == Card.RUNE_HAGALAZ or player:GetCard(1) == Card.RUNE_HAGALAZ)
    end


    --[[
        this function holds any check we need to run
        regardless of anything else
    --]]
    function tyrone.NoMatterWhat()
        -- set isaac's heart parent entity to scapegoat
        if hasIsaacsHeart then
            for i,entity in ipairs(roomEntities) do
                if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.PUNCHING_BAG then
                    punchingBagEntity = entity
                end
                if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.ISAACS_HEART then
                    entity.Parent = punchingBagEntity
                end
            end
        end
    end


    --[[
        reset the costume to Tyrone's magnificient visage
    --]]
    function tyrone.DressMeUp()
        if player:GetCollectibleCount() ~= collectibleCount or
           updateCostume == true then
            if tyroneHasPressedTheButton then
                player:AddNullCostume(costume_scheming)
                updateCostume = false
            else
                player:AddNullCostume(costume_srs)
            end

            collectibleCount = player:GetCollectibleCount()
        end
    end


    --[[
        check if the player can destroy rocks in any way
    --]]
    function tyrone.CanPlayerDestroyThings()
        if player:GetNumBombs() > 0 or
           hasEpicFetus or hasDrFetus or
           hasThunderThighs or hasLeo or
           hasTheNail or hasNotchedAxe or
           hasSamsonsChain or hasMineCrafter or
           hasSulfuricAcid or hasMamaMega or
           hasHagalaz then
           return true
       end
    end


    --[[
        play a warning sound
    --]]
    function tyrone.Achtung() -- !
        SFXManager():Play(SoundEffect.SOUND_THUMBS_DOWN, 1.0, 0, false, 1.0);
    end


    --[[
        unit test for stuff
    --]]
    function tyrone.TestMe()
        if not tyrone.CanPlayerDestroyThings() then
            for i=0,room:GetGridSize() do
                local ent = room:GetGridEntity(i)
                if ent ~= nil then
                    if ent:ToRock() ~= nil then
                        if ent:GetType() ~= GridEntityType.GRID_ROCKT and
                           ent:GetType() ~= GridEntityType.GRID_ROCK_SS then
                            local pos = ent:GetGridIndex()
                            if pos % 32 == 0 then
                                ent:SetType(GridEntityType.GRID_ROCKT)
                            end
                        end
                    end
                end
            end
        end

        return true
    end

    return tyrone
end



--[[
    update() hook wrapper
--]]
function mod:PostUpdate()

    player = Isaac.GetPlayer(0) -- store the player instance
    hasTyrone = player:HasCollectible(itemId)

    -- save up on cycles
    if not hasTyrone then
        return
    end

    -- the essentials
    floor = game:GetLevel()
    room = game:GetRoom() -- store the current room
    roomEntities = Isaac.GetRoomEntities() -- store this room's entities
    spawnSeed = room:GetSpawnSeed() -- this room's spawn seed
    dropSeed = player:GetDropRNG():GetSeed() -- this room's drop seed
    local frame = game:GetFrameCount()
    local isFiring = player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_SHOOTING ~= 0

    -- do the thing
    if tyrone == nil then
        tyrone = Tyronize()
    end

    -- track collectibles
    tyrone.CheckOutMyStuff()

    -- things we always need to do regardless of what's going on
    tyrone.NoMatterWhat()

    -- reset the costume every time a new collectible is added
    tyrone.DressMeUp()

    -- check for hazards in the room, needed for some game ruining stuff
    roomHazards = tyrone.CheckForHazards()

    -- unit tests
    tyrone.TestMe()

    --[[
        if tyrone hasn't pressed the button yet and this room
        isn't blacklisted (the button hasn't been pressed here yet)
        see if tyrone feels like pressing the button
    --]]
    if not tyroneHasPressedTheButton and not tyRooms[spawnSeed] then
        tyroneHasPressedTheButton = tyrone.Please()
    end

    --[[
        if the button has been pressed, blacklist the room and roll
        karma
    --]]
    if tyroneHasPressedTheButton and not ruinedYet and not noticedYet then
        if not tyRooms[spawnSeed] and karma == 0 then
            tyRooms[spawnSeed] = true
            updateCostume = true
        end

        -- play sound and only roll karma once
        if karma == 0 then
            tyrone.Achtung()
            karma = random(1, 3)
            _log[0] = "karma is " .. karma
        end

        -- try and ruin synergies, don't expire the button unless satisfied
        if karma == 1 then
            _log[1] = "Tyrone wants to ruin your synergies"
            ruinedYet = tyrone.RuinSynergies()

        -- try and ruin the game, don't expire the button unless satisfied
        elseif karma == 2 then
            _log[1] = "Tyrone wants to ruin your game"
            ruinedYet = tyrone.RuinGame()

        -- try and be good but expire the button if you can't act right now
        elseif karma == 3 then
            _log[1] = "Tyrone-senpai noticed you"
            noticedYet = tyrone.NoticeMe()
            if not noticedYet then
                _log[2] = "Tyrone-senpai has stopped caring"
                tyroneHasPressedTheButton = false
                noticedYet = false
                updateCostume = false
            end
        end
    end

    --[[
        if tyrone has pressed the button and he's
        satisfied of the outcome, reset the status
    --]]
    if tyroneHasPressedTheButton and (ruinedYet or noticedYet) then
        _log[2] = "Tyrone has succeeded"
        tyroneHasPressedTheButton = false
        ruinedYet = false
        noticedYet = false
        updateCostume = false
        karma = 0
    end

end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.PostUpdate)


--[[
    cache calls updates
--]]
function mod:EvaluateCache(player, cacheFlag)
    -- no more flying
    if cacheFlag == CacheFlag.CACHE_FLYING then
        canFly = player.CanFly
    end

    -- no more spectral or piercing tears
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)


--[[
    debug output and init
--]]
function mod:PostRender()
    if player == nil then
        player = Isaac.GetPlayer(0)
    end

    hasTyrone = player:HasCollectible(itemId)

    if not hasTyrone then
        return
    end

    for i = 0, #_log do
        if _log[i] ~= nil then
            Isaac.RenderText(_log[i], 50, 40 + (i * 10), 0, 255, 0, 255)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.PostRender)
