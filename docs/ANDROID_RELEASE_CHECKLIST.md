# Android Release Checklist

## Safety & quality
- [x] Offline startup: ad initialization is optional and cannot block gameplay.
- [x] Local progress recovery uses SharedPreferences.
- [x] Basic local validation rejects invalid level/score/time values.
- [x] Puzzle generator validates a guaranteed route and independently searches the board.
- [x] Flutter CI runs format, analyze and tests.

## Performance/profile check
Run on a physical Android device in profile mode before release:

```bash
flutter run --profile
```

Check frame performance, memory and startup time with Flutter DevTools. Avoid judging release performance from debug mode.

## Android device testing
Test at minimum:
- Level selection and level launch.
- Correct/wrong arrow movement.
- Pause/resume/restart.
- Hints and coin rewards.
- Daily reward and daily challenge.
- App background/foreground recovery.
- Dark/light theme and different screen sizes.
- Offline play with network disabled.

## Release APK/AAB
The repository currently does not contain the generated Flutter `android/` project, so signing and Gradle release configuration cannot be safely added yet.

After the Android platform is generated/configured:

```bash
flutter build appbundle --release
```

Optionally create a release APK for direct device testing:

```bash
flutter build apk --release
```

Configure a private upload keystore and `key.properties`; never commit keystore files, passwords, or signing secrets.

## Play Store readiness
Before publishing:
- Set a final application ID/package name.
- Configure release signing.
- Replace Google test AdMob IDs with the production IDs and required platform configuration.
- Verify app name, icon, screenshots and store listing.
- Complete the required Play Console declarations and content/privacy forms.
- Test the signed AAB on real devices.
- Upload the AAB to Play Console and review pre-launch checks.
