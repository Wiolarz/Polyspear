# Multiplayer Doc 

We picked the route of using ENet GDscript wrappers directly.

We are not using Godots multiplayer and RPC code.

We send simple hand tailored messages with a Dictionary.

`name` field defines message type, e.g.
 - "set_session"
 - "kicked"
 - "replay_game_move"
 - "chat"

Server maintains a Session object for each connected client Peer.

Sessions are assigned to a given username to allow reconnects in the future. Usernames should be unique, or sessions will get conflicts.

Clients communicate with server only. No client to client communication.

## Key architectural drivers

- Pierożek wanted to write this code
- high control over networking if needed
- no need to learn Godot Networking and Rpc quirks
- easier if deciding to support dedicated servers
- we don't foresee any complex sync scenarios, we need
  - sync game setup info (map + selected factions/armies)
  - send 2 coordinates when army/unit moves
  - send some simple ids when buying buildings, swapping units, leveling up a hero etc.
  - (maybe) send serialized replay/snapshot for reconnect after client state loss or to support save/load for multiplayer games

## Why it's doable
Player base at the start will be pretty hardcore, so asking players to setup a hamachi/other means
to ease making multiplayer work on developers' part makes it a viable option.

Some quality of life improvements like setting up some dedicated servers, so users can simply connect to them would be nice though.

## Not in scope

We don't care about cheating nor advanced tools to avoid desync

We may even help desync with debug commands to check what happens in those scenarios.

It's a learning project intended to be forked not an esport