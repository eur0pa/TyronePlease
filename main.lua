--[[
    thanks to "Loli" for Mei's clean code
--]]

-- register the mod
local mod = RegisterMod("Tyrone", 1)

-- mod ids for easier access
local itemId = Isaac.GetItemIdByName("Nicalis Curse")
local costume = Isaac.GetCostumeIdByPath("gfx/characters/tyroneshead.anm2")

-- collectible tracking
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
local collectibleCount = 0

local _debug = nil
local _debug = {}
local game = Game()             -- game instance
local player = nil              -- player instance
local sfxManager = SFXManager() -- sfx instance
local roomEntities = nil        -- entity list per room
local costumeEquipped = false   -- player has goatee
local oldRoom = nil             -- store the previous room
local room = nil                -- store the current room
local tyRooms = {}              -- things we fucked with
local floor = 0
local canFly = false            -- can we fly?
local tyrone = nil              -- fuck shit up
local punchingBagEntity = nil
local tyroneHasPressedTheButton = false
local ruinedYet = false
local noticedYet = false
local lastIdleTime = game:GetFrameCount()
local dropSeed = nil
local spawnSeed = nil
local tyroneSeed = nil


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

        spawnSeed = room:GetSpawnSeed()
        dropSeed = player:GetDropRNG():GetSeed()
        tyroneSeed = spawnSeed ~ dropSeed

        _debug[1] =
               spawnSeed .. " ^ "
            .. dropSeed .. " = "
            .. tyroneSeed

        return tyroneSeed % 5 == 0

    end

    --[[
        tyrone loves you!
    --]]
    function tyrone.NoticeMe()

        local karma = dropSeed % math.floor(random(1 + 1) + player.Luck)
        _debug[5] = "Good Karma is " .. karma

        if karma == 1 then
            if hasBrimstone and not hasLumpOfCoal then
                player:AddCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL, 0, false)
                return true
            end
        end

        return false

    end

    --[[
        ruin the game in creative ways.
        - if the button is pressed, mangle it and derive something to ruin
        - if nothing can be ruined (choice is not applicable), expire the button
    --]]
    function tyrone.RuinGame()

        local karma = dropSeed % math.floor(random(2 + 1) + player.Luck)
        _debug[5] = "Bad Karma is " .. karma

        if karma == 1 then
            if player:GetActiveCharge() > 0 then
                player:SetActiveCharge(player:GetActiveCharge() - 1)
                return true
            end
        elseif karma == 2 then
            if hasTheD6 and not player:NeedsCharge() then
                player:SetActiveCharge(player:GetActiveCharge() - 1)
                return true
            end
        end

        return false

    end

    --[[
        ruin good synergies
        - if the button is pressed go through the synergies and ruin one
        - reset the button afterwards
    --]]
    function tyrone.RuinSynergies()

        if hasBrimstone and not hasProptosis then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS, 0, false)
            return true
        end

        if hasWhoreOfBabylon then
            if not hasTheBody then
                player:AddCollectible(CollectibleType.COLLECTIBLE_BODY, 0, false)
            end
            if not hasPlacenta then
                player:AddCollectible(CollectibleType.COLLECTIBLE_PLACENTA, 0, false)
            end
            return true
        end

        if hasLordOfThePit and not hasThunderThigs then
            player:AddCollectible(CollectibleType.COLLECTIBLE_THUNDER_THIGHS, 0, false)
            return true
        end

        if (hasSacredHeart or hasGodHead) and not hasEvesMascara then
            player:AddCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA, 0, false)
            return true
        end

        if hasIsaacsHeart and not hasPunchingBag then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PUNCHING_BAG, 0, false)
            return true
        end

        if hasIsaacsHeart then
            for i,entity in ipairs(roomEntities) do
                if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.PUNCHING_BAG then
                    punchingBagEntity = entity
                end
                if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == FamiliarVariant.ISAACS_HEART then
                    entity.Parent = punchingBagEntity
                end
            end
            return true
        end

        if hasBloodyLust and not hasAbaddon then
            player:AddCollectible(CollectibleType.COLLECTIBLE_ABADDON, 0, false)
            return true
        end

        if hasProptosis and not hasNumberOne and not hasBrimstone then
            player:AddCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE, 0, false)
            return true
        end

        if hasMonstrosLung and not hasCursedEye then
            player:AddCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE, 0, false)
            return true
        end

        if hasFireMind and not hasCricketsBody then
            player:AddCollectible(CollectibleType.COLLECTIBLE_CRICKETS_BODY, 0, false)
            return true
        end

        if hasEpicFetus and not hasTheWiz then
            player:AddCollectible(CollectibleType.COLLECTIBLE_THE_WIZ, 0, false)
            return true
        end

        if hasDrFetus then
            if not hasTheWiz then
                player:AddCollectible(CollectibleType.COLLECTIBLE_THE_WIZ, 0, false)
            end
            if not hasTinyPlanet then
                player:AddCollectible(CollectibleType.COLLECTIBLE_TINY_PLANET, 0, false)
            end
            return true
        end

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

        if hasSpeedBall and not hasBucketOfLard then
            player:AddCollectible(CollectibleType.COLLECTIBLE_BUCKET_LARD, 0, false)
            return true
        end

        if hasLostContact and not hasPolyphemus then
            player:AddCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS, 0, false)
            return true
        end

        if hasSkeletonKey and not hasPayToPlay then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY, 0, false)
            return true
        end

        if hasMomsKnife and not hasTinyPlanet then
            player:AddCollectible(CollectibleType.COLLECTIBLE_TINY_PLANET, 0, false)
            return true
        end

        if hasSadBombs then
            if not hasScatterBombs then
                player:AddCollectible(CollectibleType.COLLECTIBLE_SCATTER_BOMBS, 0, false)
            end
            if not hasBomberBoy then
                player:AddCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY, 0, false)
            end
            return true
        end

        if hasJudasShadow then
            if not hasTheBody then
                player:AddCollectible(CollectibleType.COLLECTIBLE_BODY, 0, false)
            end
            if not hasFullHP then
                player:SetFullHearts()
            end
            return true
        end

        if hasTranscendence and not hasGuillotine then
            player:AddCollectible(CollectibleType.COLLECTIBLE_GUILLOTINE, 0, false)
            return true
        end

        if hasIpecac and not hasMyReflection then
            player:AddCollectible(CollectibleType.COLLECTIBLE_MY_REFLECTION, 0, false)
            return true
        end

        if hasChocolateMilk and not hasKidneyStone then
            player:AddCollectible(CollectibleType.COLLECTIBLE_KIDNEY_STONE, 0, false)
            return true
        end

        if hasSacrificialDagger and not hasBrokenWatch then
            player:AddCollectible(CollectibleType.COLLECTIBLE_BROKEN_WATCH, 0, false)
            return true
        end

        if hasNumberTwo and not hasBomberBoy then
            player:AddCollectible(CollectibleType.COLLECTIBLE_BOMBER_BOY, 0, false)
            return true
        end

        if has8InchNails and not hasPisces then
            player:AddCollectible(CollectibleType.COLLECTIBLE_PISCES, 0, false)
            return true
        end

        if hasMagicMushroom and not hasLibra then
            player:AddCollectible(CollectibleType.COLLECTIBLE_LIBRA, 0, false)
            return true
        end

        return false

    end

    return tyrone
end



--[[
    update() hook wrapper
--]]

function mod:PostUpdate()

    player = Isaac.GetPlayer(0) -- store the player instance
    hasTyrone = player:HasCollectible(itemId)

    if not hasTyrone then
        return
    end

    floor = game:GetLevel()
    oldRoom = room -- save the old room
    room = game:GetRoom() -- store the current room
    roomEntities = Isaac.GetRoomEntities() -- store this room's entities
    local frame = game:GetFrameCount()
    local isFiring = player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_SHOOTING ~= 0

    -- track collectibles
    hasBrimstone = player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
    hasWhoreOfBabylon = player:HasCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
    hasTheBody = player:HasCollectible(CollectibleType.COLLECTIBLE_BODY)
    hasPlacenta = player:HasCollectible(CollectibleType.COLLECTIBLE_PLACENTA)
    hasLordOfThePit = player:HasCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT)
    hasThunderThigs = player:HasCollectible(CollectibleType.COLLECTIBLE_THUNDER_THIGHS)
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

    if player:GetCollectibleCount() ~= collectibleCount then
        player:AddNullCostume(costume)
        collectibleCount = player:GetCollectibleCount()
    end

    -- do the thing
    if tyrone == nil then
        tyrone = Tyronize()
    end

    tyroneHasPressedTheButton = tyrone.Please()

    if not tyRooms[spawnSeed] then

        _debug[3] = "Harmless room"

        if tyroneHasPressedTheButton and not ruinedYet then

            tyRooms[spawnSeed] = true
            _debug[3] = "Room was added to the blacklist"

            local karma = random(1)
            _debug[4] = "RNG Karma is " .. karma

            if karma == 1 then
                _debug[2] = "Tyrone wants to ruin your synergies"
                ruinedYet = tyrone.RuinSynergies()
            else
                _debug[2] = "Tyrone wants to ruin your game"
                ruinedYet = tyrone.RuinGame()
            end

            -- todo: add mercy option
        end

        if tyroneHasPressedTheButton and ruinedYet then
            _debug[2] = "Tyrone has succeeded"
            tyroneHasPressedTheButton = false
            ruinedYet = false
        end

    else
        _debug[3] = "Room is blacklisted"
    end

end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.PostUpdate)


function mod:EvaluateCache(_, player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FLYING then
        canFly = player:CanFly()
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)


function mod:PostRender()
    if player == nil then
        player = Isaac.GetPlayer(0)
    end

    hasTyrone = player:HasCollectible(itemId)

    if not hasTyrone then
        return
    end

    if _debug ~= nil then
        for i=1,#_debug do
            Isaac.RenderText(_debug[i], 50, 20 + i*10, 0, 255, 0, 255)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.PostRender)
