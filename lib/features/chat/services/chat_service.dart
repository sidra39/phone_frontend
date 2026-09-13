import '../../../core/network/api_client.dart';

class ChatRoomModel {
  final int id;
  final int customerId;
  final int vendorId;
  final int partId;
  final String modelName;
  final String? brandName;
  final String? imageUrl;
  final String? otherName;
  final String? otherCity;
  final String? customerName;
  final String? vendorShopName;
  final String createdAt;

  ChatRoomModel({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.partId,
    required this.modelName,
    this.brandName,
    this.imageUrl,
    this.otherName,
    this.otherCity,
    this.customerName,
    this.vendorShopName,
    required this.createdAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      customerId: json['customer_id'] is int ? json['customer_id'] : int.parse(json['customer_id'].toString()),
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : int.parse(json['vendor_id'].toString()),
      partId: json['part_id'] is int ? json['part_id'] : int.parse(json['part_id'].toString()),
      modelName: json['model_name'] ?? 'Part listing',
      brandName: json['brand_name'],
      imageUrl: json['image_url'],
      otherName: json['other_name'] ?? json['customer_name'] ?? json['vendor_shop_name'] ?? 'Direct Message',
      otherCity: json['other_city'],
      customerName: json['customer_name'],
      vendorShopName: json['vendor_shop_name'],
      createdAt: json['created_at'] != null ? json['created_at'].toString() : '',
    );
  }
}

class ChatMessageModel {
  final int id;
  final int roomId;
  final int senderId;
  final String message;
  final String senderName;
  final String senderRole;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    required this.senderName,
    required this.senderRole,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      message: json['message'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderRole: json['sender_role'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class ChatService {
  final ApiClient _apiClient;

  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create or retrieve chat room for customer-vendor-part
  Future<ChatRoomModel> createOrGetRoom(String token, int partId) async {
    final response = await _apiClient.post(
      '/chat/rooms',
      {'part_id': partId},
      token: token,
    );
    return ChatRoomModel.fromJson(response['data']);
  }

  /// Get active rooms for user
  Future<List<ChatRoomModel>> getMyRooms(String token) async {
    final response = await _apiClient.get('/chat/rooms', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => ChatRoomModel.fromJson(item)).toList();
  }

  /// Get message history in room
  Future<List<ChatMessageModel>> getRoomMessages(String token, int roomId) async {
    final response = await _apiClient.get('/chat/rooms/$roomId/messages', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => ChatMessageModel.fromJson(item)).toList();
  }

  /// Send message to room
  Future<ChatMessageModel> sendMessage(String token, int roomId, String message) async {
    final response = await _apiClient.post(
      '/chat/rooms/$roomId/messages',
      {'message': message},
      token: token,
    );
    return ChatMessageModel.fromJson(response['data']);
  }
}
