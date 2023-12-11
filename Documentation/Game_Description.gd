# Game Description

var General_Description
"""
Shmup called 'Spejz 3' is a classic Shoot'em up.

Story presents the player as a part of partisan force attempting to disrupt the planet's blockade.
In each gameplay segment he will enter that planet orbit. Depending on how close he is to the planet's surface
he will encounter more enemies. Each flight ends up in either the destruction of his ship or safe return to his small space station.



Table of contents of this document:
Damage system - how damage is dealt in this game



"""

var Damage_system
"""
Every ship health bar is split into a series of chunks. Depletion of the last one results in the destruction of the ship
regardless of the state of the earlier layers.

Damage sources like bullets have their Armor Penetration 'AP' value. At 0, bullet is forced to destroy every earlier layer in order to deal any damage to the core.
AP 1 deals damage both to the front layer as well as to the layer behind it.
Most common type of AP ammo consist of Explosive 'E' component, which is the damage it deals additionally to it's last layer which it managed to pierce.

In cases where damage from the attack destroys the layer, damage is transfered to the next layer.
If AP bullet destroys the core of the ship / standalone barrier or it's AP value overflows it's target.
Bullet isn't removed from the game, and it continues it's flight in search of the next target. (in weakened by the damage already dealt, state)
"""



var Progression
"""
Destruction of the enemy cargo ships rewards the player with special loot which is automaticly transfered to the station.
Based on the damage done, player's army will supply his station with better gear.

Using his aquaired wealth, player will be able to use during his flights:
- Different ship hulls
- Gun turrets
- Guns
"""


var Player_ship_design
"""
Every few flights army intelligence will inform the player what type of enemy ships will be deployed during the next few flights.
Depending on this information, player will be forced to adapt picking sometimes even cheaper ships in order to counter the enemy weaknesses.

The larger the ship player picks up for his mission, the more enemies it will attract resulting in larger scale battles. (bigger != better/more expensive)

"""


var Graphical_Architecture
"""
Because of large number of different guns ship may carry, and clutter it would create, all guns are simplified to the 'turret gun' sprite.


"""

