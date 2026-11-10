import 'app_database.dart';
import 'drift_store.dart';
import 'local_store.dart';

Future<LocalStore> createLocalStore() async {
  final database = await AppDatabase.open();
  final store = DriftStore(database);
  await store.init();
  return store;
}
