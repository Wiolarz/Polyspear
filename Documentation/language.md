# Ubiquitous Language 

see https://www.dremio.com/wiki/ubiquitous-language

in short - make sure that terms like player, unit, etc are properly chosen and defined to prevent confusion, when talking with other developers or players

In particular common terms that are poorly defined and confusing should be avoided.

And terms specific for a particular project might need to be introduced. Ideally in a way that doesn't collide with less strict terms used when talking about the game.

## Dictionary

- (skirmish, game, playthrough? find good term) - a single game on a single map, either world or battle

- world - game mode where players collect goods, control mines, level up heroes, buid builldings and armies

- battle - game mode for armies, either standalone "skirmish" of a single battle or a battle subgame in world mode, battle has no goods and has separate tactical maps for tactically manouvering units

- slot - represents a separate entity that can fight or be allied to other slots, both in battle and world modes
  - slot id - integrer that determines turn order, starts with 0, id's should be consecutive but some slots may be eliminated during the game, or skip turns in certain phases
  - color - each slot has a color assigned that makes slot graphically distinct from other slots
  - race - defines available heroes, units and buildnigs in world mode, in battle mode race is irrelevant as of 2024-07-12
  - ai - a slot can be controlled by an AI
  - player filter (currently not implemented, but shown on UI) in multiplayer network game limits witch client can control witch slot

- goods - wood, irton, ruby - resources used as currency in world mode, do not use world "resource" as it is a basic class in Godot and will be confusing

- city - key tile type in world mode, each slot needs to control a city or it will be eliminated from the game (maybe in a few turns), city allows recruitment of heroes and units, and building new buildings

- hero - in world mode moving through the map requires a hero, hero has an army and a unit representing the hero, heroes level up

- army - a set of units, controlled by a slot, usually related to some spacce on world map (a hero, a city, protercting outpost, on a hunt spot)

- hunt - a tile type in world mode, has an army that can be killed to get goods

- outpost - tile type in world mode, outpost can be controlled by a slot, outpost gives goods per turn, some buildings require controls of an outpost of a given type

- buildings - can be build in a city in order to recruit new unit types, some buildings are build on outposts controlled by a given slot

- unit - units ar parts of armies, units are always a single entity without progression (if hero levels up they can bbe represented by a different unit, but unit itself does not grow),  units have symbols on each side that affect combat mode

- symbol - each side of a hex with a unit has a symbol assigned, like Sword, Shield, Spear, Bow, Push; this affects how unit fights in combat

