module engine.font.fatlas;
import engine.backend.texture;
import inmath;
import bindbc.freetype;
import bindbc.sdl;
import std.math : quantize;
import engine.utils;
import engine.log;


struct FontAtlasItem {
    /**
        Which frame this was last used at 
    */
    ulong lastUsed;

    /**
        UV area of the glyph item
    */
    rect area;

    /**
        UV area of the glyph item
    */
    rect uvarea;

    /**
        Glyph Size
    */
    uint size;

    /**
        FreeType glyph index
    */
    uint glyphIdx;

    /**
        Whether the font item is bold
    */
    bool bold;
    
    /**
        Whether the font item is italic
    */
    bool italic;
}

class FontSlabAllocator {
private:
    ulong rootSize;
    ulong slabSize;

    struct FontSlab {
        bool allocated = false;
        size_t itemSize = 0;
        vec2i position;
        FontAtlasItem[] items;

        size_t rcCount(size_t slabSize) {
            return slabSize/itemSize;
        }
    }

    struct LookupStruct {
        uint glyphIdx;
        uint size;
        bool bold;
        bool italics;
    }

    FontSlab[4][4] slabs;
    FontAtlasItem*[LookupStruct] charLookupTable;

    FontSlab* findOptimalSlab(rect size) {
        
        import std.stdio : writeln;

        int biggestSize = cast(int)max(size.width, size.height);
        int quantizedSize = cast(int)rpot(biggestSize);

        if (biggestSize == 0) {
            return null;
        }

        // Try to find a optimal slab first
        foreach(ref slabRow; slabs) {
            foreach(ref slab; slabRow) {
                if (!slab.allocated) continue;
                if (slab.itemSize == quantizedSize) return &slab;
            }
        }

        // Create a new slab!
        foreach(y, ref slabRow; slabs) {
            foreach(x; 0..4) {
                if (slabRow[x].allocated) continue;
                

                slabRow[x] = FontSlab(
                    true,
                    quantizedSize,
                    vec2i(cast(int)(x*slabSize), cast(int)(y*slabSize))
                );
                size_t hElements = cast(size_t)(slabSize/quantizedSize);
                slabRow[x].items.length = hElements * hElements;
                return &slabRow[x];
            }
        }

        return null;
    }

    bool addGlyph(uint glyph, uint size, bool bold, bool italics, int width, int height) {
        ulong currTime = SDL_GetTicks64();
        auto item = FontAtlasItem(
            currTime, 
            rect(
                0, 0, 
                cast(float)width, 
                cast(float)height
            ), 
            rect(
                0, 0, 
                cast(float)width/cast(float)rootSize, 
                cast(float)height/cast(float)rootSize
            ), 
            glyph, 
            bold, 
            italics
        );

        auto lookup = LookupStruct(glyph, size, bold, italics);
        
        if (width == 0 || height == 0) {
            charLookupTable[lookup] = new FontAtlasItem(currTime, rect(0, 0, 0, 0), rect(0, 0, 0, 0), size, glyph, bold, italics);
            return true;
        }

        if (auto slab = findOptimalSlab(item.area)) {

            // Attempt to replace old items
            foreach(i, ref slabItem; slab.items) {

                float slX = i%slab.rcCount(cast(size_t)slabSize);
                float slY = i/slab.rcCount(cast(size_t)slabSize); 

                // Adjust items to the slab grid
                item.area.x = cast(float)slab.position.x + cast(float)(slX*slab.itemSize);
                item.area.y = cast(float)slab.position.y + cast(float)(slY*slab.itemSize);
                item.uvarea.x = cast(float)item.area.x/rootSize;
                item.uvarea.y = cast(float)item.area.y/rootSize;

                if (slabItem.lastUsed == 0) {

                    // Add item with early exit.
                    slab.items[i] = item;
                    charLookupTable[lookup] = &slab.items[i];
                    return true;
                }

                if (currTime-slabItem.lastUsed > 100) {
                    
                    // Remove old lookup item
                    auto slLookup = LookupStruct(slabItem.glyphIdx, size, slabItem.bold, slabItem.italic);
                    if (slLookup in charLookupTable) charLookupTable.remove(slLookup);

                    slab.items[i] = item;
                    charLookupTable[lookup] = &slab.items[i];
                    return true;
                }
            }
            return false;
        }
        return false;
    }

public:
    this(size_t totalSize = 4096) {
        this.rootSize = rpot(totalSize);
        this.slabSize = totalSize/4;
    }

    bool add(uint glyphIdx, uint size, bool bold, bool italics, int width, int height) {
        auto lookup = LookupStruct(glyphIdx, size, bold, italics);
        if (lookup !in charLookupTable) {
            return addGlyph(glyphIdx, size, bold, italics, width, height);
        }
        return false;
    }

    FontAtlasItem* get(uint glyphIdx, uint size, bool bold, bool italics) {
        ulong currTime = SDL_GetTicks64();
        auto lookup = LookupStruct(glyphIdx, size, bold, italics);
        if (lookup in charLookupTable) {
            charLookupTable[lookup].lastUsed = currTime;
            return charLookupTable[lookup];
        }

        return null;
    }

    bool has(uint glyphIdx, uint size, bool bold, bool italics) {
        auto lookup = LookupStruct(glyphIdx, size, bold, italics);
        return (lookup in charLookupTable) !is null;
    }

}

class FontAtlas {
private:
    Texture atlasTexture;
    FontSlabAllocator alloc;
    uint lastGlyph;

public:
    this() {
        atlasTexture = new Texture(4096, 4096);
        alloc = new FontSlabAllocator(4096);
    }

    FontAtlasItem* get(FT_Face face, uint glyphIdx, uint size, bool bold, bool italic, out float advanceX, out float advanceY, out float offsetX, out float offsetY) {
        if (alloc.has(glyphIdx, size, bold, italic)) {
            FT_Error err = FT_Load_Glyph(face, glyphIdx, FT_LOAD_DEFAULT);
            if (err != FT_Err_Ok) {
                uwuLogError("FT Error: %s", err);
            }
        
            advanceX = face.glyph.advance.x >> 6;
            advanceY = face.glyph.advance.y >> 6;

            // TODO: Only do kerning if font has kerning info
            FT_Vector kern;
            FT_Get_Kerning(face, lastGlyph, glyphIdx, FT_Kerning_Mode.FT_KERNING_DEFAULT, &kern);
            lastGlyph = glyphIdx;

            offsetX = -(face.glyph.metrics.horiBearingX >> 6) + (kern.x >> 6);
            offsetY = (face.glyph.metrics.horiBearingY >> 6) + (kern.y >> 6) - (face.size.metrics.height >> 6);
            return alloc.get(glyphIdx, size, bold, italic);
        } else {
            FT_Error err = FT_Load_Glyph(face, glyphIdx, FT_LOAD_RENDER);
            if (err != FT_Err_Ok) {
                uwuLogError("FT Error: %s", err);
            }
            
            advanceX = face.glyph.advance.x >> 6;
            advanceY = face.glyph.advance.y >> 6;
            
            FT_Vector kern;
            FT_Get_Kerning(face, lastGlyph, glyphIdx, FT_Kerning_Mode.FT_KERNING_DEFAULT, &kern);
            lastGlyph = glyphIdx;

            offsetX = (face.glyph.metrics.horiBearingX >> 6) + (kern.x >> 6);
            offsetY = (face.glyph.metrics.horiBearingY >> 6) + (kern.y >> 6) - (face.size.metrics.height >> 6);

            if (alloc.add(glyphIdx, size, bold, italic, face.glyph.bitmap.width, face.glyph.bitmap.rows)) {
                auto allocf = alloc.get(glyphIdx, size, bold, italic);

                if (allocf.area.width == 0) return allocf;

                // Convert the monochrome input to RGBA, because WGPU does not support internal conversion
                ubyte[] inBuf = new ubyte[](face.glyph.bitmap.width*face.glyph.bitmap.rows*4);
                foreach(i; 0..face.glyph.bitmap.width*face.glyph.bitmap.rows) {
                    size_t ir = i*4;
                    size_t ig = ir+1;
                    size_t ib = ir+2;
                    size_t ia = ir+3;

                    float alpha = face.glyph.bitmap.buffer[i] > 0 ? 255.0/cast(float)face.glyph.bitmap.buffer[i] : 0;

                    inBuf[ir] = 255; //cast(ubyte)(255*alpha);
                    inBuf[ig] = 255; //cast(ubyte)(255*alpha);
                    inBuf[ib] = 255; //cast(ubyte)(255*alpha);
                    inBuf[ia] = face.glyph.bitmap.buffer[i];
                }

                atlasTexture.setSubData(
                    inBuf, 
                    cast(int)allocf.area.x, 
                    cast(int)allocf.area.y, 
                    cast(int)allocf.area.width, 
                    cast(int)allocf.area.height
                );
                return allocf;
            }
            return null;
        }
    }

    ref Texture getTexture() {
        return atlasTexture;
    }
}