module engine;
import engine.backend.core;
import engine.font;

void uwuInit() {
    uwuInitRenderer();
    uwuInitFonts();
}

void uwuCleanup() {
    uwuCleanupRenderer();
}