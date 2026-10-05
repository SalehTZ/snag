// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageNativeName => 'English';

  @override
  String get navSnag => 'Snag';

  @override
  String get navQueue => 'Queue';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonMore => 'More';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonView => 'View';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonNone => 'None';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonShowDetails => 'Show details';

  @override
  String get commonHideDetails => 'Hide details';

  @override
  String get commonCopyLog => 'Copy log';

  @override
  String get commonShowInFolder => 'Show in folder';

  @override
  String get commonDownloadAgain => 'Download again';

  @override
  String get commonCopyLink => 'Copy link';

  @override
  String get commonLinkCopied => 'Link copied';

  @override
  String get commonFileMissing => 'The file was moved or deleted.';

  @override
  String get commonAddedToQueue => 'Added to the queue';

  @override
  String itemsAddedToQueue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items added to the queue',
      one: '1 item added to the queue',
    );
    return '$_temp0';
  }

  @override
  String itemCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get brandMeaning => '';

  @override
  String get homeSubtitle =>
      'Paste a link from YouTube, Instagram, TikTok, X, SoundCloud, Vimeo and well over a thousand other sites.';

  @override
  String get homePaste => 'Paste';

  @override
  String get homeClipboardEmpty => 'The clipboard has no link in it.';

  @override
  String get homeClipboardTitle => 'Link in your clipboard';

  @override
  String get homeQuickDownload => 'Download now with your default settings';

  @override
  String get homeSnagButton => 'Snag';

  @override
  String get homeLookingUp => 'Looking it up... tap to cancel';

  @override
  String get homeDropTitle => 'Drop the link to snag it';

  @override
  String get homeDropNotLink => 'Drop a link from your browser, not a file.';

  @override
  String get homeSupportedSites => 'See every supported site';

  @override
  String get homeRecent => 'Recently snagged';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeInvalidLink =>
      'That does not look like a link. Paste a full address, like https://youtube.com/watch?v=...';

  @override
  String get errorBotCheck =>
      'The site wants proof you are human. Add your browser cookies in Settings > Network, then try again.';

  @override
  String get errorUnsupportedUrl =>
      'This link is not supported. Check that it points to a video or playlist page.';

  @override
  String get errorPrivate =>
      'This video is private or members-only. Cookies from a signed-in browser may help.';

  @override
  String get errorSignIn =>
      'This content needs you to be signed in. Add cookies in Settings > Network.';

  @override
  String get errorRateLimited =>
      'The site is rate-limiting you. Wait a bit, or use a proxy.';

  @override
  String get errorNetwork =>
      'Could not reach the site. Check your connection or proxy.';

  @override
  String get errorFfmpegMissing =>
      'ffmpeg is missing, so audio conversion and merging cannot run. Install it from Settings > Components.';

  @override
  String get errorFormatUnavailable =>
      'That quality is not available for this video. Try \"Best\".';

  @override
  String get errorNotInstalled =>
      'yt⁠-⁠dlp is not installed yet. Open Settings > Components to set it up.';

  @override
  String get errorNoMedia => 'No media found at this link.';

  @override
  String get errorUnexpectedOutput => 'yt⁠-⁠dlp returned something unexpected.';

  @override
  String get errorFolderNotWritable =>
      'Cannot write to the download folder. Pick another one in Settings.';

  @override
  String get errorEngineStart => 'Could not start the download engine.';

  @override
  String get errorUnknown =>
      'Something went wrong. The details below may help.';

  @override
  String get sheetVideo => 'Video';

  @override
  String get sheetAudioOnly => 'Audio only';

  @override
  String get sheetQuality => 'Quality';

  @override
  String get sheetFormat => 'Format';

  @override
  String get qualityBest => 'Best';

  @override
  String get audioOriginal => 'Original';

  @override
  String get sheetEmbedSubtitles => 'Embed subtitles';

  @override
  String get sheetSubtitlesWhenAvailable => 'When the video has them';

  @override
  String sheetSubtitlesAvailable(String languages) {
    return 'Available: $languages';
  }

  @override
  String sheetLanguagesAndMore(String languages, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$languages and $countString more';
  }

  @override
  String get sheetMoreOptions => 'More options';

  @override
  String get sheetFewerOptions => 'Fewer options';

  @override
  String get sheetTemplate => 'Command template';

  @override
  String get sheetTemplateHelper =>
      'Replaces the options above with your own yt⁠-⁠dlp flags';

  @override
  String get sheetExactFormat => 'Exact format';

  @override
  String get sheetExactFormatHelp =>
      'For when you know exactly what you want. Overrides the quality above.';

  @override
  String get sheetAudioAdded => 'audio added automatically';

  @override
  String sheetFormatId(String id) {
    return 'id $id';
  }

  @override
  String get sheetUsePreset => 'Use the quality preset instead';

  @override
  String get sheetPlaylist => 'PLAYLIST';

  @override
  String sheetSelectedOf(int selected, int total) {
    final intl.NumberFormat selectedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String selectedString = selectedNumberFormat.format(selected);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$selectedString of $totalString selected';
  }

  @override
  String get sheetSelectAll => 'Select all';

  @override
  String get sheetSelectNone => 'Select none';

  @override
  String get sheetDownloadVideo => 'Download video';

  @override
  String get sheetDownloadAudio => 'Download audio';

  @override
  String get sheetDownloadTemplate => 'Download with template';

  @override
  String sheetDownloadItems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Download $countString items',
      one: 'Download 1 item',
    );
    return '$_temp0';
  }

  @override
  String get sheetSelectSomething => 'Select something to download';

  @override
  String summaryVideo(String quality) {
    return 'Video · $quality';
  }

  @override
  String summaryAudio(String format) {
    return 'Audio · $format';
  }

  @override
  String summaryFormat(String id) {
    return 'Format $id';
  }

  @override
  String get queueTitle => 'Queue';

  @override
  String queueRetryFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retry $countString failed',
      one: 'Retry failed',
    );
    return '$_temp0';
  }

  @override
  String get queueClearFinished => 'Clear finished';

  @override
  String get queueEmptyTitle => 'All caught up';

  @override
  String get queueEmptyBody =>
      'Nothing is downloading right now. Paste a link on the Snag tab and it will show up here.';

  @override
  String get queuePasteLink => 'Paste a link';

  @override
  String queueDownloading(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Downloading ($countString)';
  }

  @override
  String queueWaiting(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Waiting ($countString)';
  }

  @override
  String queueFinished(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Finished ($countString)';
  }

  @override
  String get queueRemove => 'Remove from queue';

  @override
  String statusWaiting(String summary) {
    return 'Waiting · $summary';
  }

  @override
  String statusStarting(String summary) {
    return 'Starting · $summary';
  }

  @override
  String statusSaved(String summary) {
    return 'Saved · $summary';
  }

  @override
  String get statusDone => 'Done';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String progressOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String get queueSavedTo => 'Saved to';

  @override
  String get queueLog => 'Log';

  @override
  String get queueNoOutput => 'No output yet.';

  @override
  String get stageMerging => 'Merging video and audio';

  @override
  String get stageConvertingAudio => 'Converting audio';

  @override
  String get stageThumbnail => 'Embedding thumbnail';

  @override
  String get stageMetadata => 'Writing metadata';

  @override
  String get stageSubtitles => 'Embedding subtitles';

  @override
  String get stageSponsorBlock => 'Cutting sponsor segments';

  @override
  String get stageFinishing => 'Finishing up';

  @override
  String get stageProcessing => 'Processing';

  @override
  String get libraryTitle => 'Library';

  @override
  String libraryCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString downloads',
      one: '1 download',
    );
    return '$_temp0';
  }

  @override
  String get librarySearchHint => 'Search titles, channels, links';

  @override
  String get libraryClearSearch => 'Clear search';

  @override
  String get filterAll => 'All';

  @override
  String get filterVideo => 'Video';

  @override
  String get filterAudio => 'Audio';

  @override
  String get libraryEmptyTitle => 'Your library is empty';

  @override
  String get libraryEmptyBody =>
      'Everything you download lands here, ready to play, share or grab again.';

  @override
  String get libraryFirstVideo => 'Snag your first video';

  @override
  String get libraryNoMatches => 'No matches';

  @override
  String get libraryNothingInCategory => 'Nothing in this category yet.';

  @override
  String libraryNothingMatches(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String get libraryClearFilters => 'Clear search and filters';

  @override
  String get libraryRemove => 'Remove from library';

  @override
  String get libraryRemoved =>
      'Removed from the library. The file is still on disk.';

  @override
  String get libraryDeleteFile => 'Delete file';

  @override
  String get libraryDeleteTitle => 'Delete this file?';

  @override
  String libraryDeleteBody(String title) {
    return '\"$title\" will be removed from your device. This cannot be undone.';
  }

  @override
  String get libraryKeepIt => 'Keep it';

  @override
  String libraryDeleteFailed(String error) {
    return 'Could not delete the file: $error';
  }

  @override
  String get libraryDeleted => 'File deleted';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'yesterday';

  @override
  String unitBytes(String value) {
    return '$value B';
  }

  @override
  String unitKB(String value) {
    return '$value KB';
  }

  @override
  String unitMB(String value) {
    return '$value MB';
  }

  @override
  String unitGB(String value) {
    return '$value GB';
  }

  @override
  String unitTB(String value) {
    return '$value TB';
  }

  @override
  String unitPerSecond(String size) {
    return '$size/s';
  }

  @override
  String etaSeconds(String s) {
    return '${s}s';
  }

  @override
  String etaMinutes(String m, String s) {
    return '${m}m ${s}s';
  }

  @override
  String etaHours(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String settingsHelpTranslate(String app) {
    return 'Help translate $app';
  }

  @override
  String get settingsHelpTranslateSubtitle =>
      'Add your language with a single file on GitHub';

  @override
  String get settingsDynamicColor => 'Colors from your system';

  @override
  String get settingsDynamicColorSubtitle =>
      'Match your wallpaper or accent color';

  @override
  String get settingsAccentColor => 'Accent color';

  @override
  String get settingsDownloads => 'Downloads';

  @override
  String get settingsSaveTo => 'Save to';

  @override
  String get settingsUseDefaultFolder => 'Use the default folder';

  @override
  String get settingsOpenFolder => 'Open folder';

  @override
  String get settingsChooseFolder => 'Where should downloads go?';

  @override
  String get settingsFileName => 'File name';

  @override
  String get settingsFileNameTemplate => 'File name template';

  @override
  String get settingsFileNameHelper =>
      'yt⁠-⁠dlp output template, e.g. %(uploader)s - %(title)s.%(ext)s';

  @override
  String get settingsDefaultType => 'Default type';

  @override
  String get settingsDefaultQuality => 'Default video quality';

  @override
  String get settingsDefaultAudio => 'Default audio format';

  @override
  String get settingsCompatible => 'Prefer formats that play everywhere';

  @override
  String get settingsCompatibleSubtitle => 'H.264 + AAC in MP4 when available';

  @override
  String get settingsConcurrency => 'Downloads at the same time';

  @override
  String get settingsClipboard => 'Spot links in the clipboard';

  @override
  String get settingsClipboardSubtitle =>
      'Offer to paste a copied link on the Snag tab';

  @override
  String get settingsPlainNames => 'Plain file names';

  @override
  String get settingsPlainNamesSubtitle =>
      'ASCII only, no spaces or special characters';

  @override
  String get settingsExtras => 'Extras';

  @override
  String get settingsEmbedMetadata => 'Embed metadata';

  @override
  String get settingsEmbedMetadataSubtitle =>
      'Title, artist, date and description';

  @override
  String get settingsEmbedThumbnail => 'Embed thumbnail';

  @override
  String get settingsEmbedThumbnailSubtitle => 'Shows as cover art in players';

  @override
  String get settingsEmbedChapters => 'Embed chapters';

  @override
  String get settingsEmbedSubtitles => 'Embed subtitles by default';

  @override
  String settingsSubtitleLanguagesValue(String languages) {
    return 'Languages: $languages';
  }

  @override
  String get settingsSubtitleLanguages => 'Subtitle languages';

  @override
  String get settingsSubtitleLanguagesHelper =>
      'Comma separated, regex allowed: en.*,fa,de';

  @override
  String get settingsSponsorBlock => 'SponsorBlock';

  @override
  String get settingsSponsorBlockSubtitle =>
      'Skip sponsor segments in YouTube videos';

  @override
  String get sponsorOff => 'Off';

  @override
  String get sponsorMark => 'Mark as chapters';

  @override
  String get sponsorRemove => 'Cut them out';

  @override
  String get settingsNetwork => 'Network and sign-in';

  @override
  String get settingsBrowserCookies => 'Use cookies from browser';

  @override
  String get settingsBrowserCookiesSubtitle =>
      'Fixes \"sign in to confirm you\'re not a bot\" and private videos';

  @override
  String get settingsCookiesFile => 'Cookies file';

  @override
  String get settingsCookiesFileHint => 'Netscape-format cookies.txt';

  @override
  String get settingsCookiesRemove => 'Remove cookies file';

  @override
  String get settingsCookiesChoose => 'Choose cookies.txt';

  @override
  String get settingsProxy => 'Proxy';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsProxyHelper =>
      'e.g. socks5://127.0.0.1:1080 or http://host:port';

  @override
  String get settingsSpeedLimit => 'Speed limit';

  @override
  String get settingsUnlimited => 'Unlimited';

  @override
  String get settingsSpeedLimitHelper => 'Bytes per second, e.g. 2M or 500K';

  @override
  String get settingsAria2c => 'Use aria2c';

  @override
  String get settingsAria2cSubtitle =>
      'Faster multi-connection downloads (aria2c must be installed)';

  @override
  String get settingsPowerTools => 'Power tools';

  @override
  String get settingsTemplates => 'Command templates';

  @override
  String get settingsTemplatesSubtitle => 'Saved sets of raw yt⁠-⁠dlp flags';

  @override
  String get settingsExtraArgs => 'Extra arguments';

  @override
  String get settingsExtraArgsEmpty => 'Added to every download';

  @override
  String get settingsExtraArgsHelper =>
      'Raw yt⁠-⁠dlp flags, e.g. --no-part --geo-bypass';

  @override
  String get settingsComponents => 'Components';

  @override
  String get settingsNightly => 'Nightly yt⁠-⁠dlp';

  @override
  String get settingsNightlySubtitle =>
      'Fixes for broken sites land here first';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutLicense => 'Free and open source, GPL-3.0';

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get settingsReportProblem => 'Report a problem';

  @override
  String get settingsPoweredBy => 'Powered by yt⁠-⁠dlp';

  @override
  String get settingsPoweredBySubtitle => 'The real hero. Go star it.';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsLegal =>
      'Please only download what you have the right to.';

  @override
  String get componentInstall => 'Install';

  @override
  String get componentUpdate => 'Update';

  @override
  String get componentChecking => 'Checking...';

  @override
  String get componentUnavailable => 'Unavailable';

  @override
  String componentNotInstalled(String purpose) {
    return 'Not installed · $purpose';
  }

  @override
  String get componentUnknownVersion => 'unknown version';

  @override
  String componentManaged(String app) {
    return 'managed by $app';
  }

  @override
  String componentInstalledBy(String app) {
    return 'installed by $app';
  }

  @override
  String get componentFromSystem => 'from your system';

  @override
  String get componentFoundOnSystem => 'found on your system';

  @override
  String componentCustom(String path) {
    return 'custom: $path';
  }

  @override
  String get componentUseCustom => 'Use a custom executable...';

  @override
  String get componentStopCustom => 'Stop using the custom path';

  @override
  String componentChooseExecutable(String tool) {
    return 'Choose the $tool executable';
  }

  @override
  String get componentInstallFailed =>
      'Could not finish: check your connection and try again.';

  @override
  String get componentInstalled => 'Installed';

  @override
  String componentUpdated(String version) {
    return 'Updated to $version';
  }

  @override
  String componentUpToDate(String version) {
    return 'Already up to date ($version)';
  }

  @override
  String componentFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get componentRecommended => 'recommended';

  @override
  String get purposeYtDlp => 'The download engine. Required.';

  @override
  String get purposeFfmpeg => 'Merges video with audio and converts formats.';

  @override
  String get purposeDeno => 'JavaScript runtime that YouTube now requires.';

  @override
  String get installStarting => 'Starting';

  @override
  String get installDownloading => 'Downloading';

  @override
  String get installUnpacking => 'Unpacking';

  @override
  String get installUpdating => 'Updating';

  @override
  String installProgress(String stage, String percent) {
    return '$stage $percent';
  }

  @override
  String componentStaleSystem(String version, String app) {
    return 'Found $version on your system. $app will keep its own up-to-date copy instead.';
  }

  @override
  String supportTitle(String app) {
    return 'Keep $app free';
  }

  @override
  String supportBody(String app) {
    return '$app has no ads, no tracking and no paywall, and it never will. If it saved you some time, a small donation keeps updates coming.';
  }

  @override
  String get supportSponsors => 'GitHub Sponsors';

  @override
  String get supportCoffee => 'Buy a coffee';

  @override
  String get supportStar => 'Star on GitHub';

  @override
  String get templatesTitle => 'Command templates';

  @override
  String get templatesNew => 'New template';

  @override
  String get templatesEmptyTitle => 'No templates yet';

  @override
  String get templatesEmptyBody =>
      'Save any yt⁠-⁠dlp flags you use often, then pick them from \"More options\" when downloading.';

  @override
  String get templatesCreate => 'Create one';

  @override
  String get templatesDelete => 'Delete template';

  @override
  String get templatesDeleted => 'Template deleted';

  @override
  String get templatesEdit => 'Edit template';

  @override
  String get templatesName => 'Name';

  @override
  String get templatesNameError => 'Give it a name you will recognize';

  @override
  String get templatesFlags => 'yt⁠-⁠dlp flags';

  @override
  String get templatesFlagsError => 'Add at least one yt⁠-⁠dlp flag';

  @override
  String get templatesNoLink => 'Leave the link out; it is added for you';

  @override
  String get templatesFlagsHelper =>
      'Output folder, progress and the link are added automatically.';

  @override
  String get templatesSave => 'Save template';

  @override
  String setupWelcome(String app) {
    return 'Welcome to $app';
  }

  @override
  String setupBodyDesktop(String app) {
    return '$app runs on yt⁠-⁠dlp, the open source engine behind most good downloaders. Let\'s fetch the pieces it needs. They live inside $app\'s own folder and nothing is installed system-wide.';
  }

  @override
  String setupBodyAndroid(String app) {
    return 'Everything $app needs is built in. Two quick things and you\'re set.';
  }

  @override
  String get setupGetReady => 'Get everything ready';

  @override
  String get setupWorking => 'Setting things up...';

  @override
  String get setupSkipOptional => 'Skip the optional parts';

  @override
  String get setupStart => 'Start snagging';

  @override
  String get setupEngine => 'Download engine';

  @override
  String setupEngineBuiltIn(String version) {
    return 'yt⁠-⁠dlp $version · built in';
  }

  @override
  String get setupUpdateEngine => 'Update to the latest yt⁠-⁠dlp';

  @override
  String get setupUpdateEngineSubtitle =>
      'Sites change often, and a fresh engine fixes most problems.';

  @override
  String get setupNotifications => 'Show download progress';

  @override
  String get setupNotificationsSubtitle =>
      'A quiet notification while downloads run in the background.';

  @override
  String get setupAllowed => 'Allowed';

  @override
  String get setupLanguage => 'Language';

  @override
  String get setupStorage => 'Save to your Downloads folder';

  @override
  String get setupStorageSubtitle =>
      'This version of Android asks before apps can save files there.';

  @override
  String get folderAccessTitle => 'Allow access to this folder?';

  @override
  String folderAccessBody(String folder, String app) {
    return 'Android only lets apps save to Download and Documents on their own. To save to $folder, $app needs \"All files access\". You can turn it off at any time in system settings.';
  }

  @override
  String get folderAccessAllow => 'Allow access';

  @override
  String get folderAccessDenied =>
      'No access, so downloads stay in the current folder.';

  @override
  String get notifyDownloading => 'Downloading';

  @override
  String get supportCrypto => 'Crypto';

  @override
  String get cryptoTitle => 'Donate with crypto';

  @override
  String get cryptoBody =>
      'Listed cheapest first. Send only on the network shown: coins sent on a different network can be lost for good.';

  @override
  String get cryptoCopy => 'Copy address';

  @override
  String cryptoCopied(String network) {
    return '$network address copied';
  }

  @override
  String get cryptoLowestFees => 'Lowest fees';
}
