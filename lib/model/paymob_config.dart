class PayMobConfig {
  final String apiKey;
  final String integrationId; // Primary integration ID (first from array)
  final String iframeId; // For credit cards
  final String? walletIntegrationId; // For electronic wallets
  final String? walletIframeId; // For electronic wallets iframe
  final List<String>?
      allIntegrationIds; // All integration IDs from backend array
  bool isTest;

  PayMobConfig({
    required this.apiKey,
    required this.integrationId,
    required this.iframeId,
    this.walletIntegrationId,
    this.walletIframeId,
    this.allIntegrationIds,
    this.isTest = false,
  });

  // Helper method to get all integration IDs as array
  List<String> getAllIntegrationIds() {
    // If we have the full array from backend, use it
    if (allIntegrationIds != null && allIntegrationIds!.isNotEmpty) {
      return allIntegrationIds!;
    }

    // Otherwise, build array from individual fields (backward compatibility)
    List<String> ids = [integrationId];
    if (walletIntegrationId != null && walletIntegrationId!.isNotEmpty) {
      ids.add(walletIntegrationId!);
    }
    return ids;
  }

  // Helper method to get all iframe IDs as array
  List<String> getAllIframeIds() {
    List<String> ids = [iframeId];
    if (walletIframeId != null && walletIframeId!.isNotEmpty) {
      ids.add(walletIframeId!);
    }
    return ids;
  }

  // Helper method to check if we have wallet support
  bool hasWalletSupport() {
    final allIds = getAllIntegrationIds();
    return allIds.length > 1; // More than just card integration ID
  }

  // Helper method to get primary (card) integration ID
  String getPrimaryIntegrationId() {
    return integrationId;
  }

  // Helper method to get wallet integration IDs (excluding the first one which is for cards)
  List<String> getWalletIntegrationIds() {
    final allIds = getAllIntegrationIds();
    if (allIds.length > 1) {
      return allIds.sublist(1); // Return all except the first one
    }
    return [];
  }
}
