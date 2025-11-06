--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local DirectoryTypes = require(game.ReplicatedStorage.Game.Library.Types.Directory)
local RarityTypes = require(game.ReplicatedStorage.Game.Library.Types.Rarity)

local module = {}

export type raw_dir = {
    DisplayName: string,
    Icon: string,
    MutationIcons: {[string]: string}?,
    Rarity: RarityTypes.dir_schema,
    MoneyPerSecond: number,
    BaseUpgradeCost: number,
    BillboardOffset: number,
    RarityWeight: number,
    PedestalOffset: number?,
    IndexOffset: number?,
    IndexPositionOffset: Vector3?,
    IndexRotationOffset: Vector3?,
    BestFishMultiplier: number?,
    LuckyBlockId: string?,
    SpecialItemFish: boolean?,
    OverrideSellPrice: number?,
    DisableSpawn: boolean?,
}

export type fish_type = "Normal" | "Shiny" | "Gold" | "Rainbow"

export type data_schema = {
    UID: string,
    FishId: string,
    Type: fish_type,
    Mutation: string?,
    Traits: {[string]: boolean}?,
    Shiny: boolean?,
    Level: number,
    CreateTime: number,
    BaseTime: number,
}

export type create_params = {
    FishId: string,
    Type: fish_type,
    Mutation: string?,
    Traits: {[string]: boolean}?,
    Shiny: boolean?,
    Level: number?,
}

export type swimming_fish_schema = {
    FishData: data_schema,
    SpawnTime: number,
    Carrier: Player?,
}

export type dir_schema = raw_dir & DirectoryTypes.dir_schema

return module