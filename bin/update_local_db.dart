import 'package:update_local_db/update_local_db.dart' as update_local_db;

void main(List<String> arguments) async {
  // print('Hello world: ${update_local_db.calculate()}!');
  await update_local_db.getLastDBFile();
}
