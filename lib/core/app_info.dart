/// Single source of truth for branding. Rename the app here.
abstract final class AppInfo {
  static const name = 'Snag';
  static const tagline = 'Paste a link. Get the file.';
  static const version = '0.1.0';

  static const repoUrl = 'https://github.com/SalehTZ/snag';
  static const issuesUrl = '$repoUrl/issues';
  static const translateUrl = '$repoUrl/blob/main/TRANSLATING.md';
  static const sponsorUrl = 'https://github.com/sponsors/SalehTZ';
  static const kofiUrl = 'https://ko-fi.com/salehtz';

  static const ytDlpUrl = 'https://github.com/yt-dlp/yt-dlp';
  static const supportedSitesUrl =
      'https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md';

  /// Donation wallets, cheapest network first. Checksums verified
  /// (bech32, base58check, EIP-55) before adding; re-verify on any change.
  static const wallets = [
    Wallet(
      network: 'BNB Smart Chain',
      label: 'BSC · BEP20',
      coins: 'BNB · USDT (BEP-20)',
      address: '0xDc131f09a194957EAdD1c069765BF9e78013Ac8C',
    ),
    Wallet(
      network: 'Tron',
      label: 'TRON · TRC20',
      coins: 'TRX · USDT (TRC-20)',
      address: 'TPmJbZpicJEaG9Vj5sMLBmKvzMnyn7Bkxt',
    ),
    Wallet(
      network: 'Ethereum',
      label: 'ETH · ERC20',
      coins: 'ETH · USDT (ERC-20)',
      address: '0xDc131f09a194957EAdD1c069765BF9e78013Ac8C',
    ),
    Wallet(
      network: 'Bitcoin',
      label: 'BTC · SegWit',
      coins: 'BTC',
      address: 'bc1qahd3arfp90rpny73dp9unjhcdl32mmnkrln7uy',
    ),
  ];
}

class Wallet {
  const Wallet({
    required this.network,
    required this.label,
    required this.coins,
    required this.address,
  });

  final String network;

  /// How exchanges name the network in their withdrawal menus.
  final String label;
  final String coins;
  final String address;
}

