/// Whether paged/dual page image crossfade should run (P2-2).
///
/// Gates behind reduced motion (`MediaQuery.disableAnimations`). Strong
/// desktops keep the default fade; weak-device / first-frame-only knobs can
/// layer on later without changing call sites.
bool readerPageCrossfadeEnabled({required bool reduceMotion}) => !reduceMotion;
