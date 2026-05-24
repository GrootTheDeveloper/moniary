import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences appPreferences;

Future<void> bootstrapPreferences() async {
  appPreferences = await SharedPreferences.getInstance();
}
