/*
    Copyright © 2023, Luna the Foxgirl
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna the Foxgirl
*/
module game.mygame;
import engine.game;
import engine.render.batch;
import bindbc.wgpu;
import inmath.linalg;
import engine.input.keyboard;
import engine.backend.texture;
import inmath.hsv;
import inmath;
import core.internal.gc.impl.conservative.gc;

class MyGame : Game {
private:
    vec2 ada;
    Texture adaTex;

protected:
    override
    void onInit() {
        adaTex = new Texture("adahi.png");
        ada = vec2(0, 0);

        this.setClearColor(vec4(0, 0, 0, 1));
    }

    override
    void onFixedUpdate(float deltaTime) {
        
    }

    override
    void onUpdate(float deltaTime) {
        // KeyboardState state = Keyboard.getState();

        // float moveSpeed = 1000*deltaTime;

        // if (state.isKeyDown(Key.keyA)) ada.x -= moveSpeed;
        // if (state.isKeyDown(Key.keyD)) ada.x += moveSpeed;
        // if (state.isKeyDown(Key.keyW)) ada.y -= moveSpeed;
        // if (state.isKeyDown(Key.keyS)) ada.y += moveSpeed;
    }

    override
    void onDraw(SpriteBatch spriteBatch) {
        spriteBatch.begin();
            float currTime = getCurrentTime();
            float fudgeFactor = 16;
            float offsetBase = (256+fudgeFactor);
            float offsetX = -(16*offsetBase);
            float offsetY = -(16*offsetBase);

            float colorSpeed = 0.5;
            float colorSpeedBacking = 0.8;

            foreach(y; 0..32) {
                foreach(x; 0..32) {

                    float adaX = offsetX+(x*offsetBase)+(sin(currTime+x)*(fudgeFactor*2));
                    float adaY = offsetY+(y*offsetBase)+(cos(currTime+x)*(fudgeFactor*2));

                    spriteBatch.draw(
                        adaTex, 
                        rect(adaX, adaY, 256, 256), 
                        rect(0, 0, adaTex.getWidth(), adaTex.getHeight()),
                        vec4(hsv2rgb(vec3((1+sin((x+y+currTime)*colorSpeedBacking))/2, 0.8, 0.5)), 1)
                    );
                }
            }

            foreach(y; 0..32) {
                foreach(x; 0..32) {

                    float adaX = offsetX+(x*offsetBase)+(sin(currTime+x)*(fudgeFactor/2));
                    float adaY = offsetY+(y*offsetBase)+(cos(currTime+x)*(fudgeFactor/2));

                    spriteBatch.draw(
                        adaTex, 
                        rect(adaX, adaY, 256, 256), 
                        rect(0, 0, adaTex.getWidth(), adaTex.getHeight()),
                        vec4(hsv2rgb(vec3((1+sin((x+y+currTime)*colorSpeed))/2, 0.8, 1)), 1)
                    );
                }
            }
            

        spriteBatch.end();
    }

public:
    this() {
        super("My Game");
    }
}