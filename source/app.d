/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
import std.stdio;
import engine;
import game.mygame;

void main()
{
    uwuInit();
    MyGame myGame = new MyGame();
    myGame.start();
    uwuCleanup();
}
