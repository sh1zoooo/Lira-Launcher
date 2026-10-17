# Lira interface and Russian localization

The launcher now uses a shared graphite/violet design with light and dark semantic
colors. A custom accent and a custom photo/video background remain supported.
Without a custom background the default cards are opaque; wallpaper cards retain
the existing system material settings. Game rendering and JIT code are unchanged.

## Navigation

- Home: selected version, account switcher, original launch action, quick actions,
  searchable profiles, favorites, free storage, JIT status, download center, history,
  and Minecraft news. Favorites are scoped to each game directory and stored in
  `NSUserDefaults`; they never modify game data.
- Explore: seven horizontally scrolling content categories with full localized
  names, using the existing search, filters and download implementations.
- Assistant: existing AI tools and sessions, with localized interface and tool text.
- Instances: existing version manager and version-specific settings.
- Settings: searchable entry points for appearance, language, accounts, Java,
  controls, folders, downloads and the complete advanced preferences screen.

Home stays embedded in the existing iPhone/iPad launcher containers. The hidden
`LauncherRightPanelViewController` continues to own account/JIT/download gating
and broadcasts button availability. The new UI forwards actions to it rather than
reimplementing launch checks. Existing profile names and identifiers are preserved.

## Localization

Russian is registered in the app's language list and `CFBundleLocalizations`, so
`ru-RU` and other Russian region variants resolve to `ru`. The existing scene
rebuild on language change also rebuilds the new pages. Every English catalogue
key has a Russian value. Additional formerly inline messages in the multiplayer,
AI and migration screens are now localized. Diagnostic match tokens remain
unchanged. Logs, downloaded resource names/descriptions and third-party Java
installer interfaces are supplied by their respective sources.

Run `python3 scripts/check_localizations.py` to validate syntax, catalogue parity,
format argument types/positions and direct native localization references. The
`Lira UI checks` workflow also runs Apple's `plutil` and iOS Clang syntax checks.
The existing Development build workflow remains the full IPA/TIPA packaging check.

## Device acceptance checks

Before merging, exercise the build on iPhone and iPad in both orientations:

1. Switch system/Russian/English and reopen Home, Explore, Assistant and Settings.
2. Search profiles by name/version, toggle Favorites, select another game directory
   and verify favorites remain scoped to their original directory after restart.
3. Select a version, change account, and launch with JIT enabled/disabled. Check
   the launch/download/authentication flow and errors still come from the original
   launch controller.
4. Open every quick action and settings entry; return to Home/Settings and verify
   the navigation bar and tab selection are correct.
5. Scroll every Explore category, search, download a mod to the selected profile,
   and pause/resume from the download center.
6. Switch light/dark/system, enable a wallpaper, increase text size, and enable
   VoiceOver. Verify buttons, scrolling, rotation and theme contrast.

No device or simulator run is implied by the static checks.

## Living World (selected visual direction)

The home is now a full-bleed scenic screen with a mint launch control, a snapping instance carousel, an account avatar and a floating four-destination dock. iPhone and iPad use the same adaptive host. The right-hand motion storyboard in the concept is not an application panel.

`LiraLivingWorld` owns artwork crossfades, tilt parallax, slow scene breathing, button feedback, a launch ripple and the animated dock indicator. Reduce Motion disables spatial/repeating motion. Animation stops offscreen and when the app becomes inactive. Progress comes from `AmeLaunchProgress`, with account/JIT actions still forwarded to the existing launcher backend.

The library has responsive scenic covers, actual profile/version search, per-directory favorites and profile settings via context menus. The management action retains the original version manager. Profile settings use custom forest panels and a scenic header. Full English/Russian catalog parity remains checked by CI.

The two bundled background illustrations were generated for this redesign. They are decorative forest/nether themes assigned deterministically to profiles; they are not screenshots of a user's saved worlds. All labels, controls and status text are native UIKit views.

### Native rendering check

`bash scripts/lira-preview/run.sh` builds the production home, library, profile, dock and tab controller in a small iOS Simulator host, using clearly isolated profile/account fixtures and no game backend. It saves populated/empty-library screenshots and checks artwork, basic hit-target/scroll geometry and rapid tab navigation. This supplements iOS syntax checks and the full Development build. It does not validate JVM/JIT/game launch; those require device testing.
