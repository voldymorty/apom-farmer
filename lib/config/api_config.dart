class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'http://192.168.1.144:5000/api';
  // static const String baseUrl = 'https://apomapi.freshmindz.in/api';
  // static const String baseUrl = 'https://api.apom.in/api';

  // Auth endpoints
  static const String authLogin = '/auth/send-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  
  //Profile-Setup
  static const String profileSetup = '/auth/setup-profile';
  static const String locationStates = '/location/states';
  static const String locationDistricts = '/location/districts?state_id={state_id}&state_name={state_name}';
  static const String locationCities = '/location/cities?district_id={district_id}&district_name={district_name}';

  //Profile-Detail
  static const String profileDetail = '/auth/me';

  //Home
  static const String dashboard = '/farmers/dashboard';
  static const String marketdemand = '/farmers/market-demand?month={month}';

  //Land
  static const String landpartition = '/farmer-land';

  //Add New Pickupf
  static const String cropcatogory = "/farmer-crops/categories";
  static const String addpickup = "/farmer-crops";

  //Order
  static const String orders ="/farmer-crops?status={status}";
  static const String orderdetail = "/farmer-crops";


  //Profile
  static const String authLogout = '/auth/logout';
  static const String accountinactive = '/auth/account';
  static const String editprofile = '/auth/edit-profile';


 // Helper methods to build full URLs
  static String getAuthLoginUrl() => '$baseUrl$authLogin';
  static String getAuthVerifyOtpUrl() => '$baseUrl$authVerifyOtp';
  static String getProfileSetupUrl() => '$baseUrl$profileSetup';
  static String getProfileDetailUrl() => '$baseUrl$profileDetail';
  static String getLocationStatesUrl() => '$baseUrl$locationStates';

  static String getLocationDistrictsUrl(String stateId, String stateName) =>
      '$baseUrl${locationDistricts.replaceAll('{state_id}', stateId).replaceAll('{state_name}', Uri.encodeComponent(stateName))}';
  
  static String getLocationCitiesUrl(String districtId, String districtName) =>
      '$baseUrl${locationCities.replaceAll('{district_id}', districtId).replaceAll('{district_name}', Uri.encodeComponent(districtName))}';
  
  static String getDashboardUrl() => '$baseUrl$dashboard';
  
  static String getmarketdemandUrl(String month) =>
      '$baseUrl${marketdemand.replaceAll('{month}', Uri.encodeComponent(month))}';
  
  static String getLandpartitionUrl({String? status}) {
    final trimmed = status?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') {
      return '$baseUrl$landpartition';
    }
    return '$baseUrl$landpartition?status=${Uri.encodeComponent(trimmed)}';
  }

  static String getLandpartitionCreateUrl() => '$baseUrl$landpartition';

  static String getLandpartitionUpdateUrl(int segmentId) =>
      '$baseUrl$landpartition/$segmentId';

  static String getLandpartitionDeleteUrl(int segmentId) =>
      '$baseUrl$landpartition/$segmentId';


  static String getCropcatogoryUrl() => '$baseUrl$cropcatogory';

  static String getAddpickupUrl() => '$baseUrl$addpickup';   

  static String getOrdersUrl({String? status}) {
    final trimmed = status?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') {
      return '$baseUrl$addpickup';
    }
    return '$baseUrl${orders.replaceAll('{status}', Uri.encodeComponent(trimmed))}';
  }

  static String getOrdersUpdateUrl(int cropid) =>'$baseUrl$addpickup/$cropid';

  static String getOrdersDeleteUrl(int cropid) =>'$baseUrl$addpickup/$cropid';

  static String getOrderdetailUrl(int cropid) =>'$baseUrl$orderdetail/$cropid';

  static String getEditprofilelUrl() =>'$baseUrl$editprofile';

  static String getAuthLogoutUrl() => '$baseUrl$authLogout';   
  static String getAccountInactiveUrl() => '$baseUrl$accountinactive';

  // Farmer Subscription
  static const String subscriptionPlans = '/farmer/subscriptions/plans';
  static const String subscriptionStatus = '/farmer/subscriptions/status';
  static const String subscriptionInitiate = '/farmer/subscriptions/initiate';
  static const String subscriptionVerify = '/farmer/subscriptions/verify';
  static const String subscriptionFailure = '/farmer/subscriptions/failure';

  static String getSubscriptionPlansUrl() => '$baseUrl$subscriptionPlans';
  static String getSubscriptionStatusUrl() => '$baseUrl$subscriptionStatus';
  static String getSubscriptionInitiateUrl() => '$baseUrl$subscriptionInitiate';
  static String getSubscriptionVerifyUrl() => '$baseUrl$subscriptionVerify';
  static String getSubscriptionFailureUrl() => '$baseUrl$subscriptionFailure';

  // Notifications
  static const String notifications = '/farmer/notifications';
  static const String unreadCount = '/farmer/notifications/unread-count';
  static const String fcmToken = '/auth/fcm-token';

  static String getNotificationsUrl({int page = 1, int limit = 20}) =>
      '$baseUrl$notifications?page=$page&limit=$limit';
  static String getUnreadCountUrl() => '$baseUrl$unreadCount';
  static String getMarkReadUrl(int id) => '$baseUrl$notifications/$id/read';
  static String getMarkAllReadUrl() => '$baseUrl$notifications/read-all';
  static String getUpdateFcmTokenUrl() => '$baseUrl$fcmToken';

  static String buildDocumentUrl(String endpointPath) {
    if (endpointPath.startsWith('http://') || endpointPath.startsWith('https://')) {
      return endpointPath;
    }
    final root = baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
    final path = endpointPath.startsWith('/') ? endpointPath : '/$endpointPath';
    return '$root$path';
  }
}

