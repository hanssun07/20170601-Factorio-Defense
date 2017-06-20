# Factorio Defense
Turing-based RTS, Tower-Defense-style game inspired by [Factorio](www.factorio.com "Official Factorio Website") for my 11th grade final project.

Unlicensed.

Development began May 12, and ended June 14, 2017.

An overview of how the game was constructed can be found in [CONSTRUCTION.md](CONSTRUCTION.md).

### Objective
In this game, one balances furthering production so as to escape the hostile planet on a spaceship with keeping the hostile inhabitants at bay by manufacturing, placing, supplying, and repairing turrets.

### Interface
The map, which shows the current location of turrets and aliens at the entrance to the player's compound, is displayed as a grid on the left side of the screen. On the right is a list of stats and a slidebar, which the player uses to allocate their production. Availabe resources are shown next to their position on the slider.

Due to the fact that picture graphics for this game, in Turing, would require at least 615 separate images (yes, I counted), all items are only represented by basic graphics: red squares are aliens, coloured ovals are turrets, dots are projectiles, and darker tiles are walls.

### How to Run this Game
1. Download [Open Turing](tristan.hume.ca/openturing) and the _Factorio Defense_ folder in this repository.
2. Open `Main.t` with Open Turing, and press `F1` or the `Run` button.

### Troubleshooting
_The sound effects are terrible!_ 

Sorry, that's a problem with Turing, which only gives me three channels to work with. If you want to get rid of the constant lag, rename (or outright delete) the `Sounds/Effects` folder.
