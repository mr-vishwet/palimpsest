import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/services/blob_store.dart';
import 'package:palimpsest/widgets/frame_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MemoryItem item({String? thumbBlobId}) => MemoryItem(
        id: 'item-1',
        kind: MediaKind.photo,
        title: 'Test frame',
        takenAt: DateTime.utc(2024, 5, 12, 14, 30),
        checksum: 'checksum-item-1',
        thumbBlobId: thumbBlobId,
      );

  Future<void> pumpTile(
    WidgetTester tester, {
    required MemoryItem item,
    BlobStore? blobStore,
  }) async {
    // No network in tests: fall back to bundled fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: FrameTile(
              item: item,
              onTap: () {},
              blobStore: blobStore,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the real thumbnail when one is stored',
      (tester) async {
    final image = img.Image(width: 64, height: 48);
    img.fill(image, color: img.ColorRgb8(200, 40, 40));
    final thumbBytes = img.encodeJpg(image);
    final blobs = MemoryBlobStore();
    final thumbId = await blobs.put(thumbBytes);

    await pumpTile(
      tester,
      item: item(thumbBlobId: thumbId),
      blobStore: blobs,
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.photo_outlined), findsNothing);
  });

  testWidgets('falls back to the gradient when there is no thumbnail',
      (tester) async {
    await pumpTile(tester, item: item());

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
    expect(find.text('Test frame'), findsOneWidget);
  });

  testWidgets('falls back to the gradient when the blob is missing',
      (tester) async {
    await pumpTile(
      tester,
      item: item(thumbBlobId: 'no-such-blob'),
      blobStore: MemoryBlobStore(),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
  });
}
