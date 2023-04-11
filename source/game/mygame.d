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
import engine.font;
import std.format;

class MyGame : Game {
private:
    vec2 ada;
    Texture adaTex;
    Font font;
    float delta;

protected:
    override
    void onInit() {
        adaTex = new Texture("adahi.png");
        ada = vec2(0, 0);

        font = new Font("kosugi.ttf");

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
        delta = deltaTime;
    }

    override
    void onDraw(SpriteBatch spriteBatch) {
        spriteBatch.begin();
            float currTime = getCurrentTime();
            float fudgeFactor = 16;
            float offsetBase = (256+fudgeFactor);
            float offsetX = -(16*offsetBase);
            float offsetY = -(16*offsetBase);

            float colorSpeed = 0.15;
            float colorSpeedBacking = 0.18;

            foreach(y; 0..32) {
                foreach(x; 0..32) {

                    float adaX = offsetX+(x*offsetBase)+(sin(currTime+x)*(fudgeFactor*2));
                    float adaY = offsetY+(y*offsetBase)+(cos(currTime+x)*(fudgeFactor*2));

                    float xyCol = (cast(float)x/cast(float)y)*3;
                    float hue = mod((xyCol+(currTime*colorSpeedBacking)), 1);

                    spriteBatch.draw(
                        adaTex, 
                        rect(adaX, adaY, 256, 256), 
                        rect(0, 0, adaTex.getWidth(), adaTex.getHeight()),
                        vec4(hsv2rgb(vec3(hue, 0.8, 0.3)), 1)
                    );
                }
            }

            foreach(y; 0..32) {
                foreach(x; 0..32) {

                    float adaX = offsetX+(x*offsetBase)+(sin(currTime+x)*(fudgeFactor/2));
                    float adaY = offsetY+(y*offsetBase)+(cos(currTime+x)*(fudgeFactor/2));

                    float xyCol = (cast(float)x/cast(float)y)*3;
                    float hue = mod((xyCol+(currTime*colorSpeed)), 1);
                    spriteBatch.draw(
                        adaTex, 
                        rect(adaX, adaY, 256, 256), 
                        rect(0, 0, adaTex.getWidth(), adaTex.getHeight()),
                        vec4(hsv2rgb(vec3(hue, 0.8, 1)), 1)
                    );
                }
            }

        spriteBatch.flush();
        
            spriteBatch.draw(font, "aiueosashisusesotachitsutetokakikukeko\nAIUEOSASHISUSESOTACHITSUTETOKAKIKUKEKO\nあいうえおさしすせそたちつてとかきくけこ\nアイウエオサシスセソタチツテトカキクケコ", 80, vec2(12, 12));
            spriteBatch.draw(font, "%.2fms".format(delta*1000), 24, vec2(0, 0));

        spriteBatch.end();
    }

public:
    this() {
        super("My Game");
    }
}