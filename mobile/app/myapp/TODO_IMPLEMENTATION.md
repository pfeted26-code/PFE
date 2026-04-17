# Mobile Version Error Fixes - Implementation Plan

**Status**: In Progress

## Steps:
- [x] 1. Fix Layout.dart: Remove duplicates, add _user state, fix pass to sidebar, safe loading
- [x] 2. Update UserModel.fromJson: Null-safe parsing for sexe/role/etc.
- [ ] 3. Run `flutter pub get && flutter analyze`
- [ ] 4. Test `flutter run` on device/emulator (login flow)
- [ ] 5. Update TODO.md as completed
- [ ] 6. attempt_completion

**Notes**: Focus on compile/runtime errors from null casts.

