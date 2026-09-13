import 'package:get/get.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_customer_screen.dart';
import 'features/auth/screens/register_vendor_screen.dart';
import 'features/auth/screens/email_otp_verification_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/browse/screens/browse_home_screen.dart';
import 'features/browse/screens/part_detail_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_notification_center_screen.dart';
import 'features/admin/screens/category_management_screen.dart';
import 'features/admin/screens/commission_review_screen.dart';
import 'features/admin/screens/dashboard_stats_screen.dart';
import 'features/admin/screens/report_review_screen.dart';
import 'features/admin/screens/system_settings_screen.dart';
import 'features/admin/screens/user_management_screen.dart';
import 'features/admin/screens/vendor_management_screen.dart';
import 'features/vendor/screens/vendor_dashboard_screen.dart';
import 'features/vendor/screens/add_edit_part_screen.dart';
import 'features/vendor/screens/commission_payment_screen.dart';
import 'features/vendor/screens/leads_screen.dart';
import 'features/vendor/screens/my_commissions_screen.dart';
import 'features/vendor/screens/my_parts_screen.dart';
import 'features/vendor/screens/vendor_profile_screen.dart';
import 'features/vendor/models/part_model.dart';
import 'features/vendor/models/commission_model.dart';
import 'features/customer/screens/customer_dashboard_screen.dart';
import 'features/customer/screens/add_review_screen.dart';
import 'features/customer/screens/customer_profile_screen.dart';
import 'features/customer/screens/my_requests_screen.dart';
import 'features/customer/screens/qr_scanner_screen.dart';
import 'features/customer/screens/search_screen.dart';
import 'features/customer/models/request_model.dart';
import 'features/chat/screens/chat_rooms_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/reports/screens/my_reports_screen.dart';
import 'features/reports/screens/submit_report_screen.dart';

/// AppRoutes
/// Centralized route names and GetPage list for the Mobile Part Finder app.
/// Use Get.toNamed(AppRoutes.xxx) for navigation throughout the app.
class AppRoutes {
  // Public / Splash
  static const splash             = '/';
  static const browseHome         = '/browse';

  // Auth
  static const login              = '/login';
  static const registerCustomer   = '/register/customer';
  static const registerVendor     = '/register/vendor';
  static const emailOtpVerify     = '/auth/otp-verify';
  static const forgotPassword     = '/auth/forgot-password';
  static const resetPassword      = '/auth/reset-password';

  // Browse
  static const partDetail         = '/parts/detail';

  // Customer
  static const customerDashboard  = '/customer/dashboard';
  static const customerProfile    = '/customer/profile';
  static const myRequests         = '/customer/requests';
  static const search             = '/customer/search';
  static const addReview          = '/customer/add-review';
  static const qrScanner          = '/customer/qr-scanner';

  // Vendor
  static const vendorDashboard    = '/vendor/dashboard';
  static const vendorProfile      = '/vendor/profile';
  static const myParts            = '/vendor/parts';
  static const addEditPart        = '/vendor/parts/add-edit';
  static const leads              = '/vendor/leads';
  static const myCommissions      = '/vendor/commissions';
  static const commissionPayment  = '/vendor/commissions/pay';

  // Admin
  static const adminDashboard         = '/admin/dashboard';
  static const adminStats             = '/admin/stats';
  static const adminVendorMgmt        = '/admin/vendors';
  static const adminUserMgmt          = '/admin/users';
  static const adminCommissionReview  = '/admin/commissions';
  static const adminCategoryMgmt      = '/admin/categories';
  static const adminReportReview      = '/admin/reports';
  static const adminSystemSettings    = '/admin/settings';
  static const adminNotifications     = '/admin/notifications';

  // Shared
  static const chatRooms          = '/chat/rooms';
  static const chatScreen         = '/chat/screen';
  static const notifications      = '/notifications';
  static const myReports          = '/reports/my';
  static const submitReport       = '/reports/submit';

  // GetPage list
  static final List<GetPage> pages = [
    GetPage(name: splash,            page: () => const SplashScreen()),
    GetPage(name: browseHome,        page: () => const BrowseHomeScreen()),

    // Auth
    GetPage(name: login,             page: () => LoginScreen(returnToPartId: Get.arguments as int?)),
    GetPage(name: registerCustomer,  page: () => RegisterCustomerScreen(returnToPartId: Get.arguments as int?)),
    GetPage(name: registerVendor,    page: () => const RegisterVendorScreen()),
    GetPage(name: emailOtpVerify,    page: () {
      final args = Get.arguments as Map<String, dynamic>? ?? {};
      return EmailOtpVerificationScreen(
        email: args['email'] as String? ?? '',
        returnToPartId: args['returnToPartId'] as int?,
      );
    }),
    GetPage(name: forgotPassword,    page: () => ForgotPasswordScreen(initialEmail: Get.arguments as String?)),
    GetPage(name: resetPassword,     page: () => ResetPasswordScreen(email: (Get.arguments as String?) ?? '')),

    // Browse
    GetPage(name: partDetail,        page: () => PartDetailScreen(partId: Get.arguments as int)),

    // Customer
    GetPage(name: customerDashboard, page: () {
      final a = Get.arguments;
      return CustomerDashboardScreen(initialIndex: a is int ? a : 0);
    }),
    GetPage(name: customerProfile,   page: () => const CustomerProfileScreen()),
    GetPage(name: myRequests,        page: () => const MyRequestsScreen()),
    GetPage(name: search,            page: () => const SearchScreen()),
    // arguments: RequestModel object
    GetPage(name: addReview,         page: () => AddReviewScreen(request: Get.arguments as RequestModel)),
    // arguments: {'partId': int, 'requestId': int?}
    GetPage(name: qrScanner,         page: () {
      final a = Get.arguments as Map<String, dynamic>;
      return QrScannerScreen(partId: a['partId'] as int, requestId: a['requestId'] as int?);
    }),

    // Vendor
    GetPage(name: vendorDashboard,   page: () {
      final a = Get.arguments;
      return VendorDashboardScreen(initialIndex: a is int ? a : 0);
    }),
    GetPage(name: vendorProfile,     page: () => const VendorProfileScreen()),
    GetPage(name: myParts,           page: () => const MyPartsScreen()),
    // arguments: PartModel? object (null for add, PartModel for edit)
    GetPage(name: addEditPart,       page: () => AddEditPartScreen(partToEdit: Get.arguments as PartModel?)),
    GetPage(name: leads,             page: () => const LeadsScreen()),
    GetPage(name: myCommissions,     page: () => const MyCommissionsScreen()),
    // arguments: CommissionModel object
    GetPage(name: commissionPayment, page: () => CommissionPaymentScreen(commission: Get.arguments as CommissionModel)),

    // Admin
    GetPage(name: adminDashboard,        page: () => const AdminDashboardScreen()),
    GetPage(name: adminStats,            page: () => const DashboardStatsScreen()),
    GetPage(name: adminVendorMgmt,       page: () => const VendorManagementScreen()),
    GetPage(name: adminUserMgmt,         page: () => const UserManagementScreen()),
    GetPage(name: adminCommissionReview, page: () => const CommissionReviewScreen()),
    GetPage(name: adminCategoryMgmt,     page: () => const CategoryManagementScreen()),
    GetPage(name: adminReportReview,     page: () => const ReportReviewScreen()),
    GetPage(name: adminSystemSettings,   page: () => const SystemSettingsScreen()),
    GetPage(name: adminNotifications,    page: () => const AdminNotificationCenterScreen()),

    // Shared
    GetPage(name: chatRooms,         page: () => const ChatRoomsScreen()),
    // arguments: {'roomId': int, 'roomTitle': String, 'otherPartyName': String?}
    GetPage(name: chatScreen,        page: () {
      final a = Get.arguments as Map<String, dynamic>;
      return ChatScreen(
        roomId: a['roomId'] as int,
        roomTitle: a['roomTitle'] as String,
        otherPartyName: a['otherPartyName'] as String? ?? 'User',
      );
    }),
    GetPage(name: notifications,     page: () => const NotificationsScreen()),
    GetPage(name: myReports,         page: () => const MyReportsScreen()),
    // arguments: {'reportedUserId': int, 'requestId': int?}
    GetPage(name: submitReport,      page: () {
      final a = Get.arguments as Map<String, dynamic>;
      return SubmitReportScreen(
        reportedUserId: a['reportedUserId'] as int,
        requestId: a['requestId'] as int?,
      );
    }),
  ];
}
