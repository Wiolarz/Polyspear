# Convention for naming and separating classes DataX, X XForm
Date: 2024-05-08

Author: NamespaceV

Approvals: Wiolarz, Pierożek

Status: PARTIALLY-IMPLEMENTED 

as of 2024-05-08 Data is used consequently, form is not separated cleanly

## Decision description

We have/had code that mixed database like parameters, key behavior logic and presentation logic like sprites and animations. There was no coherent naming convention making it difficult to write and debug code.

For example units have faction, texture, symbols on each side that are constant for a given unit and edited in unit editor. There are unit behaviors like occupying a field on a battle grid, current rotation, interacting with other units that will be needed for AI, dedicated server etc. And there are purely graphical elements like displaying the texture, selecting a unit, animating unit rotation and movement that do not need to be simulated on AI and will get more and more code as we tweak the game.

Key architectural driver: improve maintainability and ease of extending the codebase

The decision is to have 3 separate classes

- `DataXyz` - constant Resource with minimal dependence's, maybe some helper functions, but should not refer to higher layers

 - `Xyz` - core logic for a particular instance in the game. Usually stores reference to data Xyz as a `var template` and has variables for non const variables like currently occupied field, should not contain graphic presentation logic

 - `XyzForm` - Graphical element with animations etc usually contains reference to Xyz on `var entity` field, Xyz should provide signals for XyzForm to listen to, so that Xyz does not have to know about XyzForm existence. In particular in scenarios like dedicated server or AI simulation there will be no XyzForm created if possible

Pros:
- relatively easy to follow
- improves readability and makes classes smaller and easier to analyze

Cons:
- more layers
- needs getting used to


## Alternatives considered

### Don't do any conventions

Pros:

- more flexibility

Cons:

- much harder to add multiplayer/replays/AI etc.
- more bugs and time loss for analyzing code
- feature development time increase
- frustration when code base becomes larger

## Details

 - basically variation on https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller pattern with
   - constant part of model separated as DataXyz Resource
   - Controller and model as Xyz
   - View as FormXyz
