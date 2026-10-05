class WaitlistStatus {
  const WaitlistStatus(
      {required this.status,
      required this.canPlay,
      this.position,
      this.totalWaiting = 0,
      this.referralCode = '',
      this.referralLink = '',
      this.referralCount = 0,
      this.pendingReferralCount = 0});
  final String status, referralCode, referralLink;
  final bool canPlay;
  final int? position;
  final int totalWaiting, referralCount, pendingReferralCount;
  factory WaitlistStatus.fromJson(Map<String, dynamic> json) => WaitlistStatus(
        status: json['status']?.toString() ?? 'none',
        canPlay: json['canPlay'] == true,
        position: json['status'] == 'waiting'
            ? (json['position'] as num?)?.toInt()
            : null,
        totalWaiting: (json['totalWaiting'] as num?)?.toInt() ?? 0,
        referralCode: json['referralCode']?.toString() ?? '',
        referralLink: json['referralLink']?.toString() ?? '',
        referralCount: (json['referralCount'] as num?)?.toInt() ?? 0,
        pendingReferralCount:
            (json['pendingReferralCount'] as num?)?.toInt() ?? 0,
      );
}

class ReferralPerson {
  const ReferralPerson({required this.name, required this.verified});
  final String name;
  final bool verified;
  factory ReferralPerson.fromJson(Map<String, dynamic> json) => ReferralPerson(
      name: json['name']?.toString() ?? 'Friend',
      verified: json['verified'] == true);
}
