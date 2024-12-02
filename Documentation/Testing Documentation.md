# Checklist before submitting a Pull Request
1 Run all GUT tests for more information about simply running a GUT tests read this: https://gut.readthedocs.io/en/v9.3.0/
2 If PR adds a new complex feature: Write or Add to a TODO list - a new GUT unit tests covering this new feature.
# Things that generally fail to work

Feature works, in single-player but doesn't in multiplayer.

If a player has a really bad internet connection, game can start acting strange.

Experimental branches tend to crash without error message.

# Known issues and why they haven't been fixed yet

## Passive Search for the solution
We aren't sure what is causing the problem but the issue is small enough to not bother with it.

---
- When a new map is saved using in-game map editor, game has to restarted to access it. - 
- When joining a server, you may get instantly disconnected forcing you to join the second time which finally works.

## Postponed Fixes
We simply put a priority on other parts of the game

---
- Large parts of world gameplay like: healing hero, capturing outpost flag showing up, two heroes spawn during a battle instead of one.
- ctrl+z crashes the game if during that turn a unit died

