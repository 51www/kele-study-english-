import 'local_store.dart';
import 'web_store.dart';

Future<LocalStore> createLocalStore() async {
  final store = await WebStore.open();
  await store.init();
  return store;
}
