abstract class PremiumRepository {
  Future<void> joinWaitlist(String userId);
  Future<bool> isOnWaitlist(String userId);
}
