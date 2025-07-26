import 'package:fake_mind/chat/data/repo/chat_repo_impl.dart';
import 'package:fake_mind/chat/domain/usecases/chat_managment_usecase.dart';

import '../../domain/usecases/message_usecase.dart';
import '../../domain/usecases/sync_usecase.dart';
import '../../data/services/offline/db_helper.dart';
import '../../data/services/firebase/firebase_service.dart';
import '../../data/services/firebase/google_generative_api_service.dart';
import '../../data/services/offline/connectivity_service.dart';
import 'chat_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatCubitFactory {
  static ChatCubit create() {
    // Initialize dependencies
    final databaseHelper = DatabaseHelper.instance;
    final repository = ChatRepositoryImpl(databaseHelper);
    final firebaseService = FirebaseService();
    final apiService = GoogleGenerativeApiService(
      apiKey: dotenv.env['API_KEY'] ?? '',
    );
    final connectivityService = ConnectivityService();

    // Create use cases
    final chatUseCase = ChatManagementUseCase(repository);
    final messageUseCase = MessageUseCase(repository);
    final syncUseCase = SyncUseCase(repository, firebaseService);

    // Create and return cubit
    return ChatCubit(
      chatRepository: repository,
      chatUseCase: chatUseCase,
      messageUseCase: messageUseCase,
      syncUseCase: syncUseCase,
      apiService: apiService,
      connectivityService: connectivityService,
      firebaseService: firebaseService, // Add this line
    );
  }
}
