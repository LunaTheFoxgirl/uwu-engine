module engine.font.font;
import engine.font.fatlas;
import engine.backend.texture;
// import bindbc.hb;
import bindbc.freetype;
import engine.font;
import std.utf;
import inmath;
import std.exception : enforce;
import std.format;

struct GlyphInfo {
    FontAtlasItem* item;
    vec2 advance;
    vec2 offset;

    bool newline;
    float newlineHeight;
}

class Font {
private:
    // FT face
    FontAtlas atlas;
    FT_Face ftface;

    bool isShaping;
    size_t idx;
    uint runcount;

    GlyphInfo[] glyphs;

    // Harfbuzz items
    // hb_buffer_t* hbbuff;
    // hb_font_t* hbfont;
    // hb_glyph_info_t* hbglyphs;
    // hb_glyph_position_t* hbpositions;

    // Pixel size of font
    uint size;

    void createFace(ubyte[] data) {
        FT_Error err = FT_New_Memory_Face(uwuGetFT(), data.ptr, cast(int)data.length, 0, &ftface);
        enforce(err == FT_Err_Ok, "Font failed to load with error code %s".format(err));
        FT_Set_Pixel_Sizes(ftface, 16, 16);

        // if (uwuShapingSupported) {
        //     hbfont = hb_ft_font_create_referenced(ftface);
        //     hb_ft_font_set_load_flags(hbfont, FT_LOAD_RENDER);
        //     hb_ft_font_set_funcs(hbfont);
        //     hbbuff = hb_buffer_create();
        // }
    }

public:
    this(string fontFile) {
        import std.file : read;
        this(cast(ubyte[])read(fontFile));
    }

    this(ubyte[] fontData) {
        createFace(fontData);
        atlas = new FontAtlas();
    }

    GlyphInfo getChar(dchar c, uint size) {
        if (this.size != size) {
            this.size = size;
            FT_Set_Pixel_Sizes(ftface, size, size);
            // if (uwuShapingSupported) hb_ft_font_changed(hbfont);
        }

        GlyphInfo info;
        info.item = atlas.get(ftface, c, size, false, false, info.advance.x, info.advance.y, info.offset.x, info.offset.y);
        return info;
    }

    void buffer(string text, uint size) {
        if (isShaping) return;
        isShaping = true;

        if (this.size != size) {
            this.size = size;
            FT_Set_Pixel_Sizes(ftface, size, size);
            // if (uwuShapingSupported) hb_ft_font_changed(hbfont);
        }
        idx = 0;
        runcount = 0;

        // if (uwuShapingSupported) {
            
        //     // Harfbuzz begin
        //     hb_buffer_reset(hbbuff);
        //     hb_buffer_add_utf8(hbbuff, text.ptr, cast(int)text.length, 0, cast(int)text.length);
        //     hb_buffer_guess_segment_properties(hbbuff);

        //     runcount = hb_buffer_get_length(hbbuff);
        //     hbglyphs = hb_buffer_get_glyph_infos(hbbuff, &runcount);
        //     hbpositions = hb_buffer_get_glyph_positions(hbbuff, &runcount);

        // } else {

            // Pre-cache entire string run
            dstring dtext = toUTF32(text);
            runcount = cast(uint)dtext.length;

            if (dtext.length > glyphs.length) glyphs.length = dtext.length;
            foreach(c; dtext) {
                if (c == '\n') {
                    glyphs[idx++] = GlyphInfo(null, vec2(0), vec2(0), true, ftface.size.metrics.height >> 6);
                    continue;
                }

                auto glyphIdx = FT_Get_Char_Index(ftface, c);

                GlyphInfo info;
                info.item = atlas.get(ftface, glyphIdx, size, false, false, info.advance.x, info.advance.y, info.offset.x, info.offset.y);
                glyphs[idx++] = info;
            }
            idx = 0;
        // }
    }

    bool next(out GlyphInfo info) {
        if (idx >= runcount) isShaping = false;
        if (!isShaping) return false;

        // if (uwuShapingSupported) {
        //     uint glyphIdx = hbglyphs[idx].codepoint;
        //     idx++;

        //     info.item = atlas.get(ftface, glyphIdx, size, false, false, info.advance.x, info.advance.y);
        //     info.offset = vec2(hbpositions.x_offset, hbpositions.y_offset);
        //     return true;
        // } else {
            info = glyphs[idx++];
            return true;
        // }
    }

    ref Texture getTexture() {
        return atlas.getTexture();
    }
}