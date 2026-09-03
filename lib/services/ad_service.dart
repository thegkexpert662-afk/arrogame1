import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Google-provided test ad unit IDs. Replace with your own AdMob IDs before
  // production release. Never ship test IDs in a production build.
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const _interstitialId = 'ca-app-pub-3940256099942544/1033173712';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  DateTime? _lastInterstitialAt;
  int _completedLevelsSinceInterstitial = 0;

  static const Duration _interstitialCooldown = Duration(seconds: 90);
  static const int _levelsBetweenInterstitials = 4;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    if (_rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (_interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _lastInterstitialAt = DateTime.now();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedAd != null;

  Future<bool> showRewarded({required void Function(AdReward reward) onReward}) async {
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    _rewardedAd = null;
    bool rewarded = false;
    ad.show(onUserEarnedReward: (_, reward) {
      rewarded = true;
      onReward(AdReward(amount: reward.amount.toInt()));
    });
    return rewarded;
  }

  /// Shows an interstitial only at a natural break, after a completed level.
  /// It will never interrupt a live move and is throttled by both level count
  /// and a 90-second cooldown.
  Future<bool> showInterstitialAfterLevel() async {
    _completedLevelsSinceInterstitial++;
    final now = DateTime.now();
    final cooldownPassed = _lastInterstitialAt == null ||
        now.difference(_lastInterstitialAt!) >= _interstitialCooldown;

    if (_completedLevelsSinceInterstitial < _levelsBetweenInterstitials ||
        !cooldownPassed ||
        _interstitialAd == null) {
      _loadInterstitial();
      return false;
    }

    final ad = _interstitialAd;
    _interstitialAd = null;
    _completedLevelsSinceInterstitial = 0;
    ad!.show();
    return true;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}

class AdReward {
  const AdReward({required this.amount});
  final int amount;
}
