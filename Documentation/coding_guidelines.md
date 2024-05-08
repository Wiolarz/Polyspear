# Coding Guidelines

- keep line length below 80 characters, if needed up to 100 characters is okish, over 100 only where really necesairy 
- follow [godot style](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
  - e. g. tabs (instead of spaces)

## Line Breaks
- 2 newlines between methods and regions
- 1 newline after #region
- 1 newline before #endregion


## Pull requests

Approve PRs using gif:

![success_meme](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHhyNnloenhwM28za3oyNWNsMDMwYzR1cWRjb3Ywb3BhYXpmZTljeCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xT0BKAB7vMb10rfnvG/giphy.gif)

## Resources
- create factory methods
  - data classes (templates) should be referenced from main classes, data class should not know about main class
    - GOOD: `Unit.create(dataUnit) -> Unit`
    - BAD: `DataUnit.create() -> Unit`
  - Form classes should reference normal classes, normal class should not know about form, it should emit signals for the form
    - more tricky, details TBD
    - GOOD: `UnitForm.create(unit) -> UnitForm`
    - BAD: `Unit.createForm() -> UnitForm`

## DataXyz, XyzForm

(not fully implemented yet, work in progress, use for new code, migrate existing)

Classes that are pure resources configuration and have only **constant values** should be placed in Resources folder and be named `DataXyz`

Classes for main logic including AI simulation, dedicated server etc have no special naming convention. They contain state that changes over the course of the game, e.g. unit position. If they are based on Data classes, variable that references data is named `template`

Classes that are audiovisual representations are named Form e.g. UnitForm, they refer to core classes using variable `entity`. Entity should provide signals for Form to update (not implemented yet) Forms should not contain variables needed for AI simulation or on dedicated server. Example - selected unit is ui only, AI doesnt need to select units to move them. Similarly all animations, visual effects etc.
