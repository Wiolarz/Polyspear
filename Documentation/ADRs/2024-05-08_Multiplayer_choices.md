# Multiplayer choices

Date: 2024-05-08

Author: NamespaceV

Approvals: Wiolarz, Pierożek

Status: IMPLEMENTED

## Decision description

We needed to decide how to implement multiplayer.

We went with solution presented by Pierożek of having our own commands (custom dictionary based RPCs), based on Godot GDScript ENet library wrapper. And not use built in RPC annotations nor multiplayer layer.

Key architectural driver was Pierożek wanting to write this code.

Pros:
- we have much control over networking, each packet is sent via our code
- we learn how to write and extend this level multiplayer layer
- we can fix security issues easier as there are less layers to check
- we don't have to learn Godot multiplayer quirks
- for this game we don't expect many complex scenarios where godot networking + rpc would provide much value, its a turn game and we will be sending basic move info only

Cons:
- custom code
- boilerplate code for creating packets and calling functions


## Alternatives considered

### Use godot multiplayer and annotated RPCs

Pros:

- default way for godot

Cons:

 - we don't need it, its more complex
  - Pierożek is concerned about code quality and security

## Details

- http://enet.bespin.org/usergroup0.html
- https://www.youtube.com/watch?v=9KnLKNlgQTo
- https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- check code for classes like client/server/command in the project