import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArchiveStore.load', () {
    test('returns null for malformed JSON', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: '{not json',
      });
      expect(await ArchiveStore().load(), isNull);
    });

    test('returns null for valid JSON with the wrong shape', () async {
      // A stale or corrupted document: valid JSON, but missing the
      // fields fromJson casts. main() awaits load() before the first
      // frame, so a throw here is a blank screen with no recovery —
      // load must return null and let the app reseed.
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: '{"version": 1}',
      });
      expect(await ArchiveStore().load(), isNull);
    });

    test('returns null for an unknown enum value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey:
            '{"version": 1, "stories": [], "items": [], "layers": [], '
            '"people": [], "places": [], "voiceNotes": [], "shareLinks": [], '
            '"moments": [], "corrections": {}, '
            '"account": {"status": "guest", "connectedSources": []}, '
            '"settings": {"offlineMode": false}, '
            '"importState": {"total": 0, "indexed": 0, '
            '"status": "no-such-status", "sourceLabel": "Camera roll"}, '
            '"onboardingSeen": false}',
      });
      expect(await ArchiveStore().load(), isNull);
    });
  });
}
