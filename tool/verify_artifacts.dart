import 'embed_fixtures.dart' as fixtures;
import 'embed_full.dart' as full;
import 'embed_unicode.dart' as unicode;
import 'generate_data.dart' as generator;

void main(List<String> args) {
  generator.main(['--check']);
  fixtures.main(['--check']);
  full.main(['--check']);
  unicode.main(['--check']);
}
