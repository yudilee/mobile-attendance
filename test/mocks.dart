import 'package:mockito/annotations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/security_service.dart';
import 'package:mobile/services/app_settings.dart';
import 'package:mobile/database/app_database.dart';

@GenerateMocks([ApiService, SecurityService, AppSettings, AppDatabase])
void main() {}
