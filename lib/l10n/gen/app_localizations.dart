import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// The name of THIS language, written in itself (e.g. 'Deutsch', 'فارسی'). Shown in the language picker.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNativeName;

  /// Bottom navigation: the main download tab. 'Snag' is the app name; keep it or transliterate.
  ///
  /// In en, this message translates to:
  /// **'Snag'**
  String get navSnag;

  /// No description provided for @navQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get navQueue;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get commonShowDetails;

  /// No description provided for @commonHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get commonHideDetails;

  /// No description provided for @commonCopyLog.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get commonCopyLog;

  /// No description provided for @commonShowInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get commonShowInFolder;

  /// No description provided for @commonDownloadAgain.
  ///
  /// In en, this message translates to:
  /// **'Download again'**
  String get commonDownloadAgain;

  /// No description provided for @commonCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get commonCopyLink;

  /// No description provided for @commonLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get commonLinkCopied;

  /// No description provided for @commonFileMissing.
  ///
  /// In en, this message translates to:
  /// **'The file was moved or deleted.'**
  String get commonFileMissing;

  /// No description provided for @commonAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to the queue'**
  String get commonAddedToQueue;

  /// No description provided for @itemsAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added to the queue} other{{count} items added to the queue}}'**
  String itemsAddedToQueue(int count);

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// What the English word 'snag' means in your language (to grab or catch something quickly), shown small next to the 'Snag.' logo on the home screen. Keep it to one or two words. Leave empty in English.
  ///
  /// In en, this message translates to:
  /// **''**
  String get brandMeaning;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a link from YouTube, Instagram, TikTok, X, SoundCloud, Vimeo and well over a thousand other sites.'**
  String get homeSubtitle;

  /// No description provided for @homePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get homePaste;

  /// No description provided for @homeClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard has no link in it.'**
  String get homeClipboardEmpty;

  /// No description provided for @homeClipboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Link in your clipboard'**
  String get homeClipboardTitle;

  /// No description provided for @homeQuickDownload.
  ///
  /// In en, this message translates to:
  /// **'Download now with your default settings'**
  String get homeQuickDownload;

  /// The main button that looks up a link. 'Snag' means grab; can be translated as a verb like 'Get it'.
  ///
  /// In en, this message translates to:
  /// **'Snag'**
  String get homeSnagButton;

  /// No description provided for @homeLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking it up... tap to cancel'**
  String get homeLookingUp;

  /// No description provided for @homeDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop the link to snag it'**
  String get homeDropTitle;

  /// No description provided for @homeDropNotLink.
  ///
  /// In en, this message translates to:
  /// **'Drop a link from your browser, not a file.'**
  String get homeDropNotLink;

  /// No description provided for @homeSupportedSites.
  ///
  /// In en, this message translates to:
  /// **'See every supported site'**
  String get homeSupportedSites;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently snagged'**
  String get homeRecent;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a link. Paste a full address, like https://youtube.com/watch?v=...'**
  String get homeInvalidLink;

  /// No description provided for @errorBotCheck.
  ///
  /// In en, this message translates to:
  /// **'The site wants proof you are human. Add your browser cookies in Settings > Network, then try again.'**
  String get errorBotCheck;

  /// No description provided for @errorUnsupportedUrl.
  ///
  /// In en, this message translates to:
  /// **'This link is not supported. Check that it points to a video or playlist page.'**
  String get errorUnsupportedUrl;

  /// No description provided for @errorPrivate.
  ///
  /// In en, this message translates to:
  /// **'This video is private or members-only. Cookies from a signed-in browser may help.'**
  String get errorPrivate;

  /// No description provided for @errorSignIn.
  ///
  /// In en, this message translates to:
  /// **'This content needs you to be signed in. Add cookies in Settings > Network.'**
  String get errorSignIn;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'The site is rate-limiting you. Wait a bit, or use a proxy.'**
  String get errorRateLimited;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the site. Check your connection or proxy.'**
  String get errorNetwork;

  /// No description provided for @errorFfmpegMissing.
  ///
  /// In en, this message translates to:
  /// **'ffmpeg is missing, so audio conversion and merging cannot run. Install it from Settings > Components.'**
  String get errorFfmpegMissing;

  /// No description provided for @errorFormatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That quality is not available for this video. Try \"Best\".'**
  String get errorFormatUnavailable;

  /// No description provided for @errorNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'yt⁠-⁠dlp is not installed yet. Open Settings > Components to set it up.'**
  String get errorNotInstalled;

  /// No description provided for @errorNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media found at this link.'**
  String get errorNoMedia;

  /// No description provided for @errorUnexpectedOutput.
  ///
  /// In en, this message translates to:
  /// **'yt⁠-⁠dlp returned something unexpected.'**
  String get errorUnexpectedOutput;

  /// No description provided for @errorFolderNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to the download folder. Pick another one in Settings.'**
  String get errorFolderNotWritable;

  /// No description provided for @errorEngineStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start the download engine.'**
  String get errorEngineStart;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. The details below may help.'**
  String get errorUnknown;

  /// No description provided for @sheetVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get sheetVideo;

  /// No description provided for @sheetAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get sheetAudioOnly;

  /// No description provided for @sheetQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get sheetQuality;

  /// No description provided for @sheetFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get sheetFormat;

  /// No description provided for @qualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get qualityBest;

  /// No description provided for @audioOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get audioOriginal;

  /// No description provided for @sheetEmbedSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Embed subtitles'**
  String get sheetEmbedSubtitles;

  /// No description provided for @sheetSubtitlesWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'When the video has them'**
  String get sheetSubtitlesWhenAvailable;

  /// No description provided for @sheetSubtitlesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {languages}'**
  String sheetSubtitlesAvailable(String languages);

  /// No description provided for @sheetLanguagesAndMore.
  ///
  /// In en, this message translates to:
  /// **'{languages} and {count} more'**
  String sheetLanguagesAndMore(String languages, int count);

  /// No description provided for @sheetMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get sheetMoreOptions;

  /// No description provided for @sheetFewerOptions.
  ///
  /// In en, this message translates to:
  /// **'Fewer options'**
  String get sheetFewerOptions;

  /// No description provided for @sheetTemplate.
  ///
  /// In en, this message translates to:
  /// **'Command template'**
  String get sheetTemplate;

  /// No description provided for @sheetTemplateHelper.
  ///
  /// In en, this message translates to:
  /// **'Replaces the options above with your own yt⁠-⁠dlp flags'**
  String get sheetTemplateHelper;

  /// No description provided for @sheetExactFormat.
  ///
  /// In en, this message translates to:
  /// **'Exact format'**
  String get sheetExactFormat;

  /// No description provided for @sheetExactFormatHelp.
  ///
  /// In en, this message translates to:
  /// **'For when you know exactly what you want. Overrides the quality above.'**
  String get sheetExactFormatHelp;

  /// No description provided for @sheetAudioAdded.
  ///
  /// In en, this message translates to:
  /// **'audio added automatically'**
  String get sheetAudioAdded;

  /// No description provided for @sheetFormatId.
  ///
  /// In en, this message translates to:
  /// **'id {id}'**
  String sheetFormatId(String id);

  /// No description provided for @sheetUsePreset.
  ///
  /// In en, this message translates to:
  /// **'Use the quality preset instead'**
  String get sheetUsePreset;

  /// No description provided for @sheetPlaylist.
  ///
  /// In en, this message translates to:
  /// **'PLAYLIST'**
  String get sheetPlaylist;

  /// No description provided for @sheetSelectedOf.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String sheetSelectedOf(int selected, int total);

  /// No description provided for @sheetSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get sheetSelectAll;

  /// No description provided for @sheetSelectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get sheetSelectNone;

  /// No description provided for @sheetDownloadVideo.
  ///
  /// In en, this message translates to:
  /// **'Download video'**
  String get sheetDownloadVideo;

  /// No description provided for @sheetDownloadAudio.
  ///
  /// In en, this message translates to:
  /// **'Download audio'**
  String get sheetDownloadAudio;

  /// No description provided for @sheetDownloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download with template'**
  String get sheetDownloadTemplate;

  /// No description provided for @sheetDownloadItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Download 1 item} other{Download {count} items}}'**
  String sheetDownloadItems(int count);

  /// No description provided for @sheetSelectSomething.
  ///
  /// In en, this message translates to:
  /// **'Select something to download'**
  String get sheetSelectSomething;

  /// No description provided for @summaryVideo.
  ///
  /// In en, this message translates to:
  /// **'Video · {quality}'**
  String summaryVideo(String quality);

  /// No description provided for @summaryAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio · {format}'**
  String summaryAudio(String format);

  /// No description provided for @summaryFormat.
  ///
  /// In en, this message translates to:
  /// **'Format {id}'**
  String summaryFormat(String id);

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Retry failed} other{Retry {count} failed}}'**
  String queueRetryFailed(int count);

  /// No description provided for @queueClearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get queueClearFinished;

  /// No description provided for @queueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get queueEmptyTitle;

  /// No description provided for @queueEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is downloading right now. Paste a link on the Snag tab and it will show up here.'**
  String get queueEmptyBody;

  /// No description provided for @queuePasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste a link'**
  String get queuePasteLink;

  /// No description provided for @queueDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading ({count})'**
  String queueDownloading(int count);

  /// No description provided for @queueWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting ({count})'**
  String queueWaiting(int count);

  /// No description provided for @queueFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished ({count})'**
  String queueFinished(int count);

  /// No description provided for @queueRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get queueRemove;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting · {summary}'**
  String statusWaiting(String summary);

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting · {summary}'**
  String statusStarting(String summary);

  /// No description provided for @statusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved · {summary}'**
  String statusSaved(String summary);

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @progressOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String progressOf(String done, String total);

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @queueSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get queueSavedTo;

  /// No description provided for @queueLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get queueLog;

  /// No description provided for @queueNoOutput.
  ///
  /// In en, this message translates to:
  /// **'No output yet.'**
  String get queueNoOutput;

  /// No description provided for @stageMerging.
  ///
  /// In en, this message translates to:
  /// **'Merging video and audio'**
  String get stageMerging;

  /// No description provided for @stageConvertingAudio.
  ///
  /// In en, this message translates to:
  /// **'Converting audio'**
  String get stageConvertingAudio;

  /// No description provided for @stageThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Embedding thumbnail'**
  String get stageThumbnail;

  /// No description provided for @stageMetadata.
  ///
  /// In en, this message translates to:
  /// **'Writing metadata'**
  String get stageMetadata;

  /// No description provided for @stageSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Embedding subtitles'**
  String get stageSubtitles;

  /// No description provided for @stageSponsorBlock.
  ///
  /// In en, this message translates to:
  /// **'Cutting sponsor segments'**
  String get stageSponsorBlock;

  /// No description provided for @stageFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing up'**
  String get stageFinishing;

  /// No description provided for @stageProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get stageProcessing;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 download} other{{count} downloads}}'**
  String libraryCount(int count);

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles, channels, links'**
  String get librarySearchHint;

  /// No description provided for @libraryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get libraryClearSearch;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get filterVideo;

  /// No description provided for @filterAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get filterAudio;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you download lands here, ready to play, share or grab again.'**
  String get libraryEmptyBody;

  /// No description provided for @libraryFirstVideo.
  ///
  /// In en, this message translates to:
  /// **'Snag your first video'**
  String get libraryFirstVideo;

  /// No description provided for @libraryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get libraryNoMatches;

  /// No description provided for @libraryNothingInCategory.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this category yet.'**
  String get libraryNothingInCategory;

  /// No description provided for @libraryNothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\".'**
  String libraryNothingMatches(String query);

  /// No description provided for @libraryClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear search and filters'**
  String get libraryClearFilters;

  /// No description provided for @libraryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get libraryRemove;

  /// No description provided for @libraryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from the library. The file is still on disk.'**
  String get libraryRemoved;

  /// No description provided for @libraryDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get libraryDeleteFile;

  /// No description provided for @libraryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this file?'**
  String get libraryDeleteTitle;

  /// No description provided for @libraryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from your device. This cannot be undone.'**
  String libraryDeleteBody(String title);

  /// No description provided for @libraryKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get libraryKeepIt;

  /// No description provided for @libraryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the file: {error}'**
  String libraryDeleteFailed(String error);

  /// No description provided for @libraryDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get libraryDeleted;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get timeYesterday;

  /// No description provided for @unitBytes.
  ///
  /// In en, this message translates to:
  /// **'{value} B'**
  String unitBytes(String value);

  /// No description provided for @unitKB.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String unitKB(String value);

  /// No description provided for @unitMB.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String unitMB(String value);

  /// No description provided for @unitGB.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String unitGB(String value);

  /// No description provided for @unitTB.
  ///
  /// In en, this message translates to:
  /// **'{value} TB'**
  String unitTB(String value);

  /// No description provided for @unitPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{size}/s'**
  String unitPerSecond(String size);

  /// No description provided for @etaSeconds.
  ///
  /// In en, this message translates to:
  /// **'{s}s'**
  String etaSeconds(String s);

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m}m {s}s'**
  String etaMinutes(String m, String s);

  /// No description provided for @etaHours.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String etaHours(String h, String m);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsHelpTranslate.
  ///
  /// In en, this message translates to:
  /// **'Help translate {app}'**
  String settingsHelpTranslate(String app);

  /// No description provided for @settingsHelpTranslateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your language with a single file on GitHub'**
  String get settingsHelpTranslateSubtitle;

  /// No description provided for @settingsDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Colors from your system'**
  String get settingsDynamicColor;

  /// No description provided for @settingsDynamicColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match your wallpaper or accent color'**
  String get settingsDynamicColorSubtitle;

  /// No description provided for @settingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentColor;

  /// No description provided for @settingsDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsDownloads;

  /// No description provided for @settingsSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to'**
  String get settingsSaveTo;

  /// No description provided for @settingsUseDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Use the default folder'**
  String get settingsUseDefaultFolder;

  /// No description provided for @settingsOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get settingsOpenFolder;

  /// No description provided for @settingsChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Where should downloads go?'**
  String get settingsChooseFolder;

  /// No description provided for @settingsFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get settingsFileName;

  /// No description provided for @settingsFileNameTemplate.
  ///
  /// In en, this message translates to:
  /// **'File name template'**
  String get settingsFileNameTemplate;

  /// No description provided for @settingsFileNameHelper.
  ///
  /// In en, this message translates to:
  /// **'yt⁠-⁠dlp output template, e.g. %(uploader)s - %(title)s.%(ext)s'**
  String get settingsFileNameHelper;

  /// No description provided for @settingsDefaultType.
  ///
  /// In en, this message translates to:
  /// **'Default type'**
  String get settingsDefaultType;

  /// No description provided for @settingsDefaultQuality.
  ///
  /// In en, this message translates to:
  /// **'Default video quality'**
  String get settingsDefaultQuality;

  /// No description provided for @settingsDefaultAudio.
  ///
  /// In en, this message translates to:
  /// **'Default audio format'**
  String get settingsDefaultAudio;

  /// No description provided for @settingsCompatible.
  ///
  /// In en, this message translates to:
  /// **'Prefer formats that play everywhere'**
  String get settingsCompatible;

  /// No description provided for @settingsCompatibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'H.264 + AAC in MP4 when available'**
  String get settingsCompatibleSubtitle;

  /// No description provided for @settingsConcurrency.
  ///
  /// In en, this message translates to:
  /// **'Downloads at the same time'**
  String get settingsConcurrency;

  /// No description provided for @settingsClipboard.
  ///
  /// In en, this message translates to:
  /// **'Spot links in the clipboard'**
  String get settingsClipboard;

  /// No description provided for @settingsClipboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer to paste a copied link on the Snag tab'**
  String get settingsClipboardSubtitle;

  /// No description provided for @settingsPlainNames.
  ///
  /// In en, this message translates to:
  /// **'Plain file names'**
  String get settingsPlainNames;

  /// No description provided for @settingsPlainNamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ASCII only, no spaces or special characters'**
  String get settingsPlainNamesSubtitle;

  /// No description provided for @settingsExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get settingsExtras;

  /// No description provided for @settingsEmbedMetadata.
  ///
  /// In en, this message translates to:
  /// **'Embed metadata'**
  String get settingsEmbedMetadata;

  /// No description provided for @settingsEmbedMetadataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Title, artist, date and description'**
  String get settingsEmbedMetadataSubtitle;

  /// No description provided for @settingsEmbedThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Embed thumbnail'**
  String get settingsEmbedThumbnail;

  /// No description provided for @settingsEmbedThumbnailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows as cover art in players'**
  String get settingsEmbedThumbnailSubtitle;

  /// No description provided for @settingsEmbedChapters.
  ///
  /// In en, this message translates to:
  /// **'Embed chapters'**
  String get settingsEmbedChapters;

  /// No description provided for @settingsEmbedSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Embed subtitles by default'**
  String get settingsEmbedSubtitles;

  /// No description provided for @settingsSubtitleLanguagesValue.
  ///
  /// In en, this message translates to:
  /// **'Languages: {languages}'**
  String settingsSubtitleLanguagesValue(String languages);

  /// No description provided for @settingsSubtitleLanguages.
  ///
  /// In en, this message translates to:
  /// **'Subtitle languages'**
  String get settingsSubtitleLanguages;

  /// No description provided for @settingsSubtitleLanguagesHelper.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, regex allowed: en.*,fa,de'**
  String get settingsSubtitleLanguagesHelper;

  /// No description provided for @settingsSponsorBlock.
  ///
  /// In en, this message translates to:
  /// **'SponsorBlock'**
  String get settingsSponsorBlock;

  /// No description provided for @settingsSponsorBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip sponsor segments in YouTube videos'**
  String get settingsSponsorBlockSubtitle;

  /// No description provided for @sponsorOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sponsorOff;

  /// No description provided for @sponsorMark.
  ///
  /// In en, this message translates to:
  /// **'Mark as chapters'**
  String get sponsorMark;

  /// No description provided for @sponsorRemove.
  ///
  /// In en, this message translates to:
  /// **'Cut them out'**
  String get sponsorRemove;

  /// No description provided for @settingsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network and sign-in'**
  String get settingsNetwork;

  /// No description provided for @settingsBrowserCookies.
  ///
  /// In en, this message translates to:
  /// **'Use cookies from browser'**
  String get settingsBrowserCookies;

  /// No description provided for @settingsBrowserCookiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fixes \"sign in to confirm you\'re not a bot\" and private videos'**
  String get settingsBrowserCookiesSubtitle;

  /// No description provided for @settingsCookiesFile.
  ///
  /// In en, this message translates to:
  /// **'Cookies file'**
  String get settingsCookiesFile;

  /// No description provided for @settingsCookiesFileHint.
  ///
  /// In en, this message translates to:
  /// **'Netscape-format cookies.txt'**
  String get settingsCookiesFileHint;

  /// No description provided for @settingsCookiesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove cookies file'**
  String get settingsCookiesRemove;

  /// No description provided for @settingsCookiesChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose cookies.txt'**
  String get settingsCookiesChoose;

  /// No description provided for @settingsProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get settingsProxy;

  /// No description provided for @settingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsNotSet;

  /// No description provided for @settingsProxyHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. socks5://127.0.0.1:1080 or http://host:port'**
  String get settingsProxyHelper;

  /// No description provided for @settingsSpeedLimit.
  ///
  /// In en, this message translates to:
  /// **'Speed limit'**
  String get settingsSpeedLimit;

  /// No description provided for @settingsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get settingsUnlimited;

  /// No description provided for @settingsSpeedLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'Bytes per second, e.g. 2M or 500K'**
  String get settingsSpeedLimitHelper;

  /// No description provided for @settingsAria2c.
  ///
  /// In en, this message translates to:
  /// **'Use aria2c'**
  String get settingsAria2c;

  /// No description provided for @settingsAria2cSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Faster multi-connection downloads (aria2c must be installed)'**
  String get settingsAria2cSubtitle;

  /// No description provided for @settingsPowerTools.
  ///
  /// In en, this message translates to:
  /// **'Power tools'**
  String get settingsPowerTools;

  /// No description provided for @settingsTemplates.
  ///
  /// In en, this message translates to:
  /// **'Command templates'**
  String get settingsTemplates;

  /// No description provided for @settingsTemplatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved sets of raw yt⁠-⁠dlp flags'**
  String get settingsTemplatesSubtitle;

  /// No description provided for @settingsExtraArgs.
  ///
  /// In en, this message translates to:
  /// **'Extra arguments'**
  String get settingsExtraArgs;

  /// No description provided for @settingsExtraArgsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Added to every download'**
  String get settingsExtraArgsEmpty;

  /// No description provided for @settingsExtraArgsHelper.
  ///
  /// In en, this message translates to:
  /// **'Raw yt⁠-⁠dlp flags, e.g. --no-part --geo-bypass'**
  String get settingsExtraArgsHelper;

  /// No description provided for @settingsComponents.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get settingsComponents;

  /// No description provided for @settingsNightly.
  ///
  /// In en, this message translates to:
  /// **'Nightly yt⁠-⁠dlp'**
  String get settingsNightly;

  /// No description provided for @settingsNightlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fixes for broken sites land here first'**
  String get settingsNightlySubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutLicense.
  ///
  /// In en, this message translates to:
  /// **'Free and open source, GPL-3.0'**
  String get settingsAboutLicense;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSourceCode;

  /// No description provided for @settingsReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get settingsReportProblem;

  /// No description provided for @settingsPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by yt⁠-⁠dlp'**
  String get settingsPoweredBy;

  /// No description provided for @settingsPoweredBySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The real hero. Go star it.'**
  String get settingsPoweredBySubtitle;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Please only download what you have the right to.'**
  String get settingsLegal;

  /// No description provided for @componentInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get componentInstall;

  /// No description provided for @componentUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get componentUpdate;

  /// No description provided for @componentChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get componentChecking;

  /// No description provided for @componentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get componentUnavailable;

  /// No description provided for @componentNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed · {purpose}'**
  String componentNotInstalled(String purpose);

  /// No description provided for @componentUnknownVersion.
  ///
  /// In en, this message translates to:
  /// **'unknown version'**
  String get componentUnknownVersion;

  /// No description provided for @componentManaged.
  ///
  /// In en, this message translates to:
  /// **'managed by {app}'**
  String componentManaged(String app);

  /// No description provided for @componentInstalledBy.
  ///
  /// In en, this message translates to:
  /// **'installed by {app}'**
  String componentInstalledBy(String app);

  /// No description provided for @componentFromSystem.
  ///
  /// In en, this message translates to:
  /// **'from your system'**
  String get componentFromSystem;

  /// No description provided for @componentFoundOnSystem.
  ///
  /// In en, this message translates to:
  /// **'found on your system'**
  String get componentFoundOnSystem;

  /// No description provided for @componentCustom.
  ///
  /// In en, this message translates to:
  /// **'custom: {path}'**
  String componentCustom(String path);

  /// No description provided for @componentUseCustom.
  ///
  /// In en, this message translates to:
  /// **'Use a custom executable...'**
  String get componentUseCustom;

  /// No description provided for @componentStopCustom.
  ///
  /// In en, this message translates to:
  /// **'Stop using the custom path'**
  String get componentStopCustom;

  /// No description provided for @componentChooseExecutable.
  ///
  /// In en, this message translates to:
  /// **'Choose the {tool} executable'**
  String componentChooseExecutable(String tool);

  /// No description provided for @componentInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish: check your connection and try again.'**
  String get componentInstallFailed;

  /// No description provided for @componentInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get componentInstalled;

  /// No description provided for @componentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated to {version}'**
  String componentUpdated(String version);

  /// No description provided for @componentUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date ({version})'**
  String componentUpToDate(String version);

  /// No description provided for @componentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String componentFailed(String error);

  /// No description provided for @componentRecommended.
  ///
  /// In en, this message translates to:
  /// **'recommended'**
  String get componentRecommended;

  /// No description provided for @purposeYtDlp.
  ///
  /// In en, this message translates to:
  /// **'The download engine. Required.'**
  String get purposeYtDlp;

  /// No description provided for @purposeFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'Merges video with audio and converts formats.'**
  String get purposeFfmpeg;

  /// No description provided for @purposeDeno.
  ///
  /// In en, this message translates to:
  /// **'JavaScript runtime that YouTube now requires.'**
  String get purposeDeno;

  /// No description provided for @installStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get installStarting;

  /// No description provided for @installDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get installDownloading;

  /// No description provided for @installUnpacking.
  ///
  /// In en, this message translates to:
  /// **'Unpacking'**
  String get installUnpacking;

  /// No description provided for @installUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get installUpdating;

  /// No description provided for @installProgress.
  ///
  /// In en, this message translates to:
  /// **'{stage} {percent}'**
  String installProgress(String stage, String percent);

  /// No description provided for @componentStaleSystem.
  ///
  /// In en, this message translates to:
  /// **'Found {version} on your system. {app} will keep its own up-to-date copy instead.'**
  String componentStaleSystem(String version, String app);

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep {app} free'**
  String supportTitle(String app);

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'{app} has no ads, no tracking and no paywall, and it never will. If it saved you some time, a small donation keeps updates coming.'**
  String supportBody(String app);

  /// No description provided for @supportSponsors.
  ///
  /// In en, this message translates to:
  /// **'GitHub Sponsors'**
  String get supportSponsors;

  /// No description provided for @supportCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy a coffee'**
  String get supportCoffee;

  /// No description provided for @supportStar.
  ///
  /// In en, this message translates to:
  /// **'Star on GitHub'**
  String get supportStar;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Command templates'**
  String get templatesTitle;

  /// No description provided for @templatesNew.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get templatesNew;

  /// No description provided for @templatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get templatesEmptyTitle;

  /// No description provided for @templatesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save any yt⁠-⁠dlp flags you use often, then pick them from \"More options\" when downloading.'**
  String get templatesEmptyBody;

  /// No description provided for @templatesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get templatesCreate;

  /// No description provided for @templatesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get templatesDelete;

  /// No description provided for @templatesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templatesDeleted;

  /// No description provided for @templatesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get templatesEdit;

  /// No description provided for @templatesName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get templatesName;

  /// No description provided for @templatesNameError.
  ///
  /// In en, this message translates to:
  /// **'Give it a name you will recognize'**
  String get templatesNameError;

  /// No description provided for @templatesFlags.
  ///
  /// In en, this message translates to:
  /// **'yt⁠-⁠dlp flags'**
  String get templatesFlags;

  /// No description provided for @templatesFlagsError.
  ///
  /// In en, this message translates to:
  /// **'Add at least one yt⁠-⁠dlp flag'**
  String get templatesFlagsError;

  /// No description provided for @templatesNoLink.
  ///
  /// In en, this message translates to:
  /// **'Leave the link out; it is added for you'**
  String get templatesNoLink;

  /// No description provided for @templatesFlagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Output folder, progress and the link are added automatically.'**
  String get templatesFlagsHelper;

  /// No description provided for @templatesSave.
  ///
  /// In en, this message translates to:
  /// **'Save template'**
  String get templatesSave;

  /// No description provided for @setupWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {app}'**
  String setupWelcome(String app);

  /// No description provided for @setupBodyDesktop.
  ///
  /// In en, this message translates to:
  /// **'{app} runs on yt⁠-⁠dlp, the open source engine behind most good downloaders. Let\'s fetch the pieces it needs. They live inside {app}\'s own folder and nothing is installed system-wide.'**
  String setupBodyDesktop(String app);

  /// No description provided for @setupBodyAndroid.
  ///
  /// In en, this message translates to:
  /// **'Everything {app} needs is built in. Two quick things and you\'re set.'**
  String setupBodyAndroid(String app);

  /// No description provided for @setupGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get everything ready'**
  String get setupGetReady;

  /// No description provided for @setupWorking.
  ///
  /// In en, this message translates to:
  /// **'Setting things up...'**
  String get setupWorking;

  /// No description provided for @setupSkipOptional.
  ///
  /// In en, this message translates to:
  /// **'Skip the optional parts'**
  String get setupSkipOptional;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Start snagging'**
  String get setupStart;

  /// No description provided for @setupEngine.
  ///
  /// In en, this message translates to:
  /// **'Download engine'**
  String get setupEngine;

  /// No description provided for @setupEngineBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'yt⁠-⁠dlp {version} · built in'**
  String setupEngineBuiltIn(String version);

  /// No description provided for @setupUpdateEngine.
  ///
  /// In en, this message translates to:
  /// **'Update to the latest yt⁠-⁠dlp'**
  String get setupUpdateEngine;

  /// No description provided for @setupUpdateEngineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sites change often, and a fresh engine fixes most problems.'**
  String get setupUpdateEngineSubtitle;

  /// No description provided for @setupNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show download progress'**
  String get setupNotifications;

  /// No description provided for @setupNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet notification while downloads run in the background.'**
  String get setupNotificationsSubtitle;

  /// No description provided for @setupAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get setupAllowed;

  /// No description provided for @setupLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get setupLanguage;

  /// No description provided for @setupStorage.
  ///
  /// In en, this message translates to:
  /// **'Save to your Downloads folder'**
  String get setupStorage;

  /// No description provided for @setupStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This version of Android asks before apps can save files there.'**
  String get setupStorageSubtitle;

  /// No description provided for @folderAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow access to this folder?'**
  String get folderAccessTitle;

  /// No description provided for @folderAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Android only lets apps save to Download and Documents on their own. To save to {folder}, {app} needs \"All files access\". You can turn it off at any time in system settings.'**
  String folderAccessBody(String folder, String app);

  /// No description provided for @folderAccessAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get folderAccessAllow;

  /// No description provided for @folderAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'No access, so downloads stay in the current folder.'**
  String get folderAccessDenied;

  /// Android notification title while downloading; shown as 'Downloading (3)' for several items.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get notifyDownloading;

  /// No description provided for @supportCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get supportCrypto;

  /// No description provided for @cryptoTitle.
  ///
  /// In en, this message translates to:
  /// **'Donate with crypto'**
  String get cryptoTitle;

  /// No description provided for @cryptoBody.
  ///
  /// In en, this message translates to:
  /// **'Listed cheapest first. Send only on the network shown: coins sent on a different network can be lost for good.'**
  String get cryptoBody;

  /// No description provided for @cryptoCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get cryptoCopy;

  /// No description provided for @cryptoCopied.
  ///
  /// In en, this message translates to:
  /// **'{network} address copied'**
  String cryptoCopied(String network);

  /// No description provided for @cryptoLowestFees.
  ///
  /// In en, this message translates to:
  /// **'Lowest fees'**
  String get cryptoLowestFees;

  /// label is the network name used by exchanges, e.g. 'BSC · BEP20'. Keep it as is.
  ///
  /// In en, this message translates to:
  /// **'Pick this network when withdrawing: {label}'**
  String cryptoNetworkLabel(String label);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
