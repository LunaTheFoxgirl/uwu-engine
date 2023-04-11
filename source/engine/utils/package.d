module engine.utils;

/**
    Rounds value to closest power of 2
*/
ulong rpot(ulong v) {
    // Early escape for values that would be rounded up to max value
    if (v > 9_223_372_036_854_775_808) return ulong.max;

    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v |= v >> 32;
    v++;
    return v;   
}