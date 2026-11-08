import 'package:flutter_test/flutter_test.dart';
import 'package:phantom/models/track.dart';

void main() {
  test('Track se sauvegarde et se recharge sans perte', () {
    const t = Track(
      id: '42',
      title: 'Nuit',
      artist: 'Moi',
      sourceId: 'audius',
      durationSeconds: 180,
    );
    final copy = Track.fromJson(t.toJson());
    expect(copy, t);
    expect(copy.title, 'Nuit');
    expect(copy.durationSeconds, 180);
    expect(copy.key, 'audius:42');
  });
}
