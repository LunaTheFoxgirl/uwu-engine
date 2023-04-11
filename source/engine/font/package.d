module engine.font;
import bindbc.freetype;
// import bindbc.hb;
import engine.log;

public import engine.font.font;


private {
    bool uwuFontsSupported_;
    bool uwuShapingSupported_;

    FT_Library ftLib;
}

void uwuInitFonts() {
    FTSupport fsupport = loadFreeType();
    uwuFontsSupported_ = fsupport != FTSupport.noLibrary && fsupport != FTSupport.badLibrary;
    if (uwuFontsSupported_) {
        FT_Init_FreeType(&ftLib);

        // HBSupport hsupport = loadHarfBuzz();
        // uwuShapingSupported_ = hsupport != HBSupport.noLibrary && hsupport != HBSupport.badLibrary;
    }

    uwuLogInfo("Fonts: %s...", uwuFontsSupported_ ? "supported" : "unsupported");
    uwuLogInfo("Shaping: %s...", uwuShapingSupported_ ? "supported" : "unsupported");
}

FT_Library uwuGetFT() {
    return ftLib;
}

bool uwuFontsSupported() {
    return uwuFontsSupported_;
}

bool uwuShapingSupported() {
    return uwuShapingSupported_;
}