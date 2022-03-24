-----------------------------------
-- Area: Escha_ZiTah
-----------------------------------
require("scripts/globals/zone")
-----------------------------------

zones = zones or {}

zones[xi.zone.ESCHA_ZITAH] =
{
    text =
    {
        ITEM_CANNOT_BE_OBTAINED     = 6383, -- You cannot obtain the <item>. Come back after sorting your inventory.
        ITEM_OBTAINED               = 6389, -- Obtained: <item>.
        GIL_OBTAINED                = 6390, -- Obtained <number> gil.
        KEYITEM_OBTAINED            = 6392, -- Obtained key item: <keyitem>.
        ITEMS_OBTAINED              = 6398, -- You obtain <number> <item>!
        CARRIED_OVER_POINTS         = 7000, -- You have carried over <number> login point[/s].
        LOGIN_CAMPAIGN_UNDERWAY     = 7001, -- The [/January/February/March/April/May/June/July/August/September/October/November/December] <number> Login Campaign is currently underway!<space>
        LOGIN_NUMBER                = 7002, -- In celebration of your most recent login (login no. <number>), we have provided you with <number> points! You currently have a total of <number> points.
        LEVEL_OF_DIFFICULTY_IS      = 7016, -- The level of difficulty for this content is <number>.
        KI_POP_TRADE                = 7461, -- A pleasure. A bloomin' pleasure.
    },
    mob =
    {
    },
    npc =
    {
    },
}

return zones[xi.zone.ESCHA_ZITAH]
