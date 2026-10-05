// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get languageNativeName => 'فارسی';

  @override
  String get navSnag => 'دانلود';

  @override
  String get navQueue => 'صف';

  @override
  String get navLibrary => 'کتابخانه';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get commonCancel => 'انصراف';

  @override
  String get commonSave => 'ذخیره';

  @override
  String get commonClear => 'پاک کردن';

  @override
  String get commonDismiss => 'بستن';

  @override
  String get commonMore => 'بیشتر';

  @override
  String get commonOpen => 'باز کردن';

  @override
  String get commonView => 'مشاهده';

  @override
  String get commonUndo => 'واگرد';

  @override
  String get commonNone => 'هیچ‌کدام';

  @override
  String get commonRetry => 'تلاش دوباره';

  @override
  String get commonTryAgain => 'دوباره امتحان کن';

  @override
  String get commonShowDetails => 'نمایش جزئیات';

  @override
  String get commonHideDetails => 'پنهان کردن جزئیات';

  @override
  String get commonCopyLog => 'کپی گزارش';

  @override
  String get commonShowInFolder => 'نمایش در پوشه';

  @override
  String get commonDownloadAgain => 'دانلود دوباره';

  @override
  String get commonCopyLink => 'کپی لینک';

  @override
  String get commonLinkCopied => 'لینک کپی شد';

  @override
  String get commonFileMissing => 'فایل جابه‌جا یا حذف شده است.';

  @override
  String get commonAddedToQueue => 'به صف اضافه شد';

  @override
  String itemsAddedToQueue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString مورد به صف اضافه شد',
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
      other: '$countString مورد',
    );
    return '$_temp0';
  }

  @override
  String get brandMeaning => 'قاپیدن';

  @override
  String get homeSubtitle =>
      'لینکی از یوتیوب، اینستاگرام، تیک‌تاک، ایکس، ساندکلاد، ویمیو یا بیش از هزار سایت دیگر بچسبانید.';

  @override
  String get homePaste => 'چسباندن';

  @override
  String get homeClipboardEmpty => 'در کلیپ‌بورد لینکی نیست.';

  @override
  String get homeClipboardTitle => 'یک لینک در کلیپ‌بورد شماست';

  @override
  String get homeQuickDownload => 'دانلود فوری با تنظیمات پیش‌فرض';

  @override
  String get homeSnagButton => 'بگیر';

  @override
  String get homeLookingUp => 'در حال بررسی... برای لغو بزنید';

  @override
  String get homeDropTitle => 'لینک را رها کنید تا دانلود شود';

  @override
  String get homeDropNotLink => 'یک لینک از مرورگر رها کنید، نه فایل.';

  @override
  String get homeSupportedSites => 'فهرست همه‌ی سایت‌های پشتیبانی‌شده';

  @override
  String get homeRecent => 'دانلودهای اخیر';

  @override
  String get homeSeeAll => 'همه';

  @override
  String get homeInvalidLink =>
      'این شبیه لینک نیست. یک آدرس کامل بچسبانید، مثل https://youtube.com/watch?v=...';

  @override
  String get errorBotCheck =>
      'سایت می‌خواهد مطمئن شود ربات نیستید. کوکی‌های مرورگرتان را در تنظیمات › شبکه اضافه کنید و دوباره امتحان کنید.';

  @override
  String get errorUnsupportedUrl =>
      'این لینک پشتیبانی نمی‌شود. مطمئن شوید به صفحه‌ی یک ویدیو یا پلی‌لیست اشاره می‌کند.';

  @override
  String get errorPrivate =>
      'این ویدیو خصوصی یا مخصوص اعضاست. کوکی‌های مرورگری که با آن وارد شده‌اید ممکن است کمک کند.';

  @override
  String get errorSignIn =>
      'برای این محتوا باید وارد حساب شوید. کوکی‌ها را در تنظیمات › شبکه اضافه کنید.';

  @override
  String get errorRateLimited =>
      'سایت سرعت درخواست‌هایتان را محدود کرده است. کمی صبر کنید یا از پروکسی استفاده کنید.';

  @override
  String get errorNetwork =>
      'اتصال به سایت ممکن نشد. اینترنت یا پروکسی خود را بررسی کنید.';

  @override
  String get errorFfmpegMissing =>
      'ffmpeg نصب نیست، پس تبدیل صدا و ادغام ممکن نیست. آن را از تنظیمات › اجزا نصب کنید.';

  @override
  String get errorFormatUnavailable =>
      'این کیفیت برای این ویدیو موجود نیست. «بهترین» را امتحان کنید.';

  @override
  String get errorNotInstalled =>
      'yt⁠-⁠dlp هنوز نصب نشده است. برای راه‌اندازی به تنظیمات › اجزا بروید.';

  @override
  String get errorNoMedia => 'در این لینک هیچ ویدیو یا صدایی پیدا نشد.';

  @override
  String get errorUnexpectedOutput => 'yt⁠-⁠dlp پاسخ غیرمنتظره‌ای داد.';

  @override
  String get errorFolderNotWritable =>
      'نوشتن در پوشه‌ی دانلود ممکن نیست. در تنظیمات پوشه‌ی دیگری انتخاب کنید.';

  @override
  String get errorEngineStart => 'موتور دانلود راه‌اندازی نشد.';

  @override
  String get errorUnknown => 'مشکلی پیش آمد. جزئیات زیر ممکن است کمک کند.';

  @override
  String get sheetVideo => 'ویدیو';

  @override
  String get sheetAudioOnly => 'فقط صدا';

  @override
  String get sheetQuality => 'کیفیت';

  @override
  String get sheetFormat => 'فرمت';

  @override
  String get qualityBest => 'بهترین';

  @override
  String get audioOriginal => 'اصلی';

  @override
  String get sheetEmbedSubtitles => 'افزودن زیرنویس';

  @override
  String get sheetSubtitlesWhenAvailable => 'اگر ویدیو زیرنویس داشته باشد';

  @override
  String sheetSubtitlesAvailable(String languages) {
    return 'موجود: $languages';
  }

  @override
  String sheetLanguagesAndMore(String languages, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$languages و $countString زبان دیگر';
  }

  @override
  String get sheetMoreOptions => 'گزینه‌های بیشتر';

  @override
  String get sheetFewerOptions => 'گزینه‌های کمتر';

  @override
  String get sheetTemplate => 'الگوی فرمان';

  @override
  String get sheetTemplateHelper =>
      'گزینه‌های بالا را با پرچم‌های yt⁠-⁠dlp خودتان جایگزین می‌کند';

  @override
  String get sheetExactFormat => 'فرمت دقیق';

  @override
  String get sheetExactFormatHelp =>
      'برای وقتی که دقیقاً می‌دانید چه می‌خواهید. کیفیت انتخاب‌شده در بالا نادیده گرفته می‌شود.';

  @override
  String get sheetAudioAdded => 'صدا خودکار اضافه می‌شود';

  @override
  String sheetFormatId(String id) {
    return 'شناسه $id';
  }

  @override
  String get sheetUsePreset => 'استفاده از کیفیت از پیش تعیین‌شده';

  @override
  String get sheetPlaylist => 'پلی‌لیست';

  @override
  String sheetSelectedOf(int selected, int total) {
    final intl.NumberFormat selectedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String selectedString = selectedNumberFormat.format(selected);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$selectedString از $totalString انتخاب شده';
  }

  @override
  String get sheetSelectAll => 'انتخاب همه';

  @override
  String get sheetSelectNone => 'لغو انتخاب همه';

  @override
  String get sheetDownloadVideo => 'دانلود ویدیو';

  @override
  String get sheetDownloadAudio => 'دانلود صدا';

  @override
  String get sheetDownloadTemplate => 'دانلود با الگو';

  @override
  String sheetDownloadItems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دانلود $countString مورد',
    );
    return '$_temp0';
  }

  @override
  String get sheetSelectSomething => 'چیزی برای دانلود انتخاب کنید';

  @override
  String summaryVideo(String quality) {
    return 'ویدیو · $quality';
  }

  @override
  String summaryAudio(String format) {
    return 'صدا · $format';
  }

  @override
  String summaryFormat(String id) {
    return 'فرمت $id';
  }

  @override
  String get queueTitle => 'صف دانلود';

  @override
  String queueRetryFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تلاش دوباره برای $countString ناموفق',
      one: 'تلاش دوباره برای ناموفق',
    );
    return '$_temp0';
  }

  @override
  String get queueClearFinished => 'پاک کردن تمام‌شده‌ها';

  @override
  String get queueEmptyTitle => 'همه‌چیز تمام است';

  @override
  String get queueEmptyBody =>
      'الان چیزی در حال دانلود نیست. لینکی را در زبانه‌ی دانلود بچسبانید تا اینجا نمایش داده شود.';

  @override
  String get queuePasteLink => 'چسباندن لینک';

  @override
  String queueDownloading(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'در حال دانلود ($countString)';
  }

  @override
  String queueWaiting(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'در انتظار ($countString)';
  }

  @override
  String queueFinished(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تمام‌شده ($countString)';
  }

  @override
  String get queueRemove => 'حذف از صف';

  @override
  String statusWaiting(String summary) {
    return 'در انتظار · $summary';
  }

  @override
  String statusStarting(String summary) {
    return 'در حال شروع · $summary';
  }

  @override
  String statusSaved(String summary) {
    return 'ذخیره شد · $summary';
  }

  @override
  String get statusDone => 'انجام شد';

  @override
  String get statusFailed => 'ناموفق';

  @override
  String get statusCancelled => 'لغو شد';

  @override
  String progressOf(String done, String total) {
    return '$done از $total';
  }

  @override
  String timeLeft(String time) {
    return '$time مانده';
  }

  @override
  String get queueSavedTo => 'ذخیره در';

  @override
  String get queueLog => 'گزارش';

  @override
  String get queueNoOutput => 'هنوز خروجی‌ای نیست.';

  @override
  String get stageMerging => 'در حال ادغام ویدیو و صدا';

  @override
  String get stageConvertingAudio => 'در حال تبدیل صدا';

  @override
  String get stageThumbnail => 'در حال افزودن تصویر کاور';

  @override
  String get stageMetadata => 'در حال نوشتن اطلاعات فایل';

  @override
  String get stageSubtitles => 'در حال افزودن زیرنویس';

  @override
  String get stageSponsorBlock => 'در حال حذف بخش‌های تبلیغاتی';

  @override
  String get stageFinishing => 'در حال اتمام';

  @override
  String get stageProcessing => 'در حال پردازش';

  @override
  String get libraryTitle => 'کتابخانه';

  @override
  String libraryCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString دانلود',
    );
    return '$_temp0';
  }

  @override
  String get librarySearchHint => 'جستجوی عنوان، کانال یا لینک';

  @override
  String get libraryClearSearch => 'پاک کردن جستجو';

  @override
  String get filterAll => 'همه';

  @override
  String get filterVideo => 'ویدیو';

  @override
  String get filterAudio => 'صدا';

  @override
  String get libraryEmptyTitle => 'کتابخانه‌تان خالی است';

  @override
  String get libraryEmptyBody =>
      'هر چه دانلود کنید اینجا می‌آید، آماده‌ی پخش، اشتراک یا دانلود دوباره.';

  @override
  String get libraryFirstVideo => 'اولین ویدیو را بگیرید';

  @override
  String get libraryNoMatches => 'نتیجه‌ای پیدا نشد';

  @override
  String get libraryNothingInCategory => 'هنوز چیزی در این دسته نیست.';

  @override
  String libraryNothingMatches(String query) {
    return 'چیزی با «$query» مطابقت ندارد.';
  }

  @override
  String get libraryClearFilters => 'پاک کردن جستجو و فیلترها';

  @override
  String get libraryRemove => 'حذف از کتابخانه';

  @override
  String get libraryRemoved => 'از کتابخانه حذف شد. فایل هنوز روی دستگاه است.';

  @override
  String get libraryDeleteFile => 'حذف فایل';

  @override
  String get libraryDeleteTitle => 'این فایل حذف شود؟';

  @override
  String libraryDeleteBody(String title) {
    return '«$title» از دستگاه شما پاک می‌شود. این کار برگشت‌پذیر نیست.';
  }

  @override
  String get libraryKeepIt => 'نگهش دار';

  @override
  String libraryDeleteFailed(String error) {
    return 'حذف فایل ممکن نشد: $error';
  }

  @override
  String get libraryDeleted => 'فایل حذف شد';

  @override
  String get timeJustNow => 'همین الان';

  @override
  String timeMinutesAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString دقیقه پیش',
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
      other: '$countString ساعت پیش',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'دیروز';

  @override
  String unitBytes(String value) {
    return '$value بایت';
  }

  @override
  String unitKB(String value) {
    return '$value کیلوبایت';
  }

  @override
  String unitMB(String value) {
    return '$value مگابایت';
  }

  @override
  String unitGB(String value) {
    return '$value گیگابایت';
  }

  @override
  String unitTB(String value) {
    return '$value ترابایت';
  }

  @override
  String unitPerSecond(String size) {
    return '$size/ثانیه';
  }

  @override
  String etaSeconds(String s) {
    return '$s ثانیه';
  }

  @override
  String etaMinutes(String m, String s) {
    return '$m دقیقه و $s ثانیه';
  }

  @override
  String etaHours(String h, String m) {
    return '$h ساعت و $m دقیقه';
  }

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingsAppearance => 'ظاهر';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تیره';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLanguageSystem => 'پیش‌فرض سیستم';

  @override
  String settingsHelpTranslate(String app) {
    return 'به ترجمه‌ی $app کمک کنید';
  }

  @override
  String get settingsHelpTranslateSubtitle =>
      'زبان خودتان را با یک فایل در گیت‌هاب اضافه کنید';

  @override
  String get settingsDynamicColor => 'رنگ‌های سیستم';

  @override
  String get settingsDynamicColorSubtitle =>
      'هماهنگ با تصویر زمینه یا رنگ اصلی سیستم';

  @override
  String get settingsAccentColor => 'رنگ اصلی';

  @override
  String get settingsDownloads => 'دانلودها';

  @override
  String get settingsSaveTo => 'ذخیره در';

  @override
  String get settingsUseDefaultFolder => 'استفاده از پوشه‌ی پیش‌فرض';

  @override
  String get settingsOpenFolder => 'باز کردن پوشه';

  @override
  String get settingsChooseFolder => 'دانلودها کجا ذخیره شوند؟';

  @override
  String get settingsFileName => 'نام فایل';

  @override
  String get settingsFileNameTemplate => 'الگوی نام فایل';

  @override
  String get settingsFileNameHelper =>
      'الگوی خروجی yt⁠-⁠dlp، مثلاً %(uploader)s - %(title)s.%(ext)s';

  @override
  String get settingsDefaultType => 'نوع پیش‌فرض';

  @override
  String get settingsDefaultQuality => 'کیفیت پیش‌فرض ویدیو';

  @override
  String get settingsDefaultAudio => 'فرمت پیش‌فرض صدا';

  @override
  String get settingsCompatible => 'فرمت‌هایی که همه‌جا پخش می‌شوند';

  @override
  String get settingsCompatibleSubtitle => 'در صورت امکان H.264 و AAC در MP4';

  @override
  String get settingsConcurrency => 'دانلود هم‌زمان';

  @override
  String get settingsClipboard => 'تشخیص لینک در کلیپ‌بورد';

  @override
  String get settingsClipboardSubtitle =>
      'پیشنهاد چسباندن لینک کپی‌شده در زبانه‌ی دانلود';

  @override
  String get settingsPlainNames => 'نام فایل ساده';

  @override
  String get settingsPlainNamesSubtitle =>
      'فقط حروف انگلیسی، بدون فاصله و نویسه‌ی خاص';

  @override
  String get settingsExtras => 'امکانات بیشتر';

  @override
  String get settingsEmbedMetadata => 'افزودن اطلاعات فایل';

  @override
  String get settingsEmbedMetadataSubtitle => 'عنوان، هنرمند، تاریخ و توضیحات';

  @override
  String get settingsEmbedThumbnail => 'افزودن تصویر کاور';

  @override
  String get settingsEmbedThumbnailSubtitle =>
      'در پخش‌کننده‌ها به‌عنوان کاور نمایش داده می‌شود';

  @override
  String get settingsEmbedChapters => 'افزودن فصل‌ها';

  @override
  String get settingsEmbedSubtitles => 'افزودن زیرنویس به‌طور پیش‌فرض';

  @override
  String settingsSubtitleLanguagesValue(String languages) {
    return 'زبان‌ها: $languages';
  }

  @override
  String get settingsSubtitleLanguages => 'زبان‌های زیرنویس';

  @override
  String get settingsSubtitleLanguagesHelper =>
      'با کاما جدا کنید، عبارت منظم مجاز است: en.*,fa,de';

  @override
  String get settingsSponsorBlock => 'SponsorBlock';

  @override
  String get settingsSponsorBlockSubtitle =>
      'رد کردن بخش‌های تبلیغاتی در ویدیوهای یوتیوب';

  @override
  String get sponsorOff => 'خاموش';

  @override
  String get sponsorMark => 'علامت‌گذاری به‌صورت فصل';

  @override
  String get sponsorRemove => 'حذف کامل';

  @override
  String get settingsNetwork => 'شبکه و ورود به حساب';

  @override
  String get settingsBrowserCookies => 'استفاده از کوکی‌های مرورگر';

  @override
  String get settingsBrowserCookiesSubtitle =>
      'رفع خطای «تأیید کنید ربات نیستید» و دسترسی به ویدیوهای خصوصی';

  @override
  String get settingsCookiesFile => 'فایل کوکی';

  @override
  String get settingsCookiesFileHint => 'فایل cookies.txt با قالب Netscape';

  @override
  String get settingsCookiesRemove => 'حذف فایل کوکی';

  @override
  String get settingsCookiesChoose => 'انتخاب cookies.txt';

  @override
  String get settingsProxy => 'پروکسی';

  @override
  String get settingsNotSet => 'تنظیم نشده';

  @override
  String get settingsProxyHelper =>
      'مثلاً socks5://127.0.0.1:1080 یا http://host:port';

  @override
  String get settingsSpeedLimit => 'محدودیت سرعت';

  @override
  String get settingsUnlimited => 'نامحدود';

  @override
  String get settingsSpeedLimitHelper => 'بایت بر ثانیه، مثلاً 2M یا 500K';

  @override
  String get settingsAria2c => 'استفاده از aria2c';

  @override
  String get settingsAria2cSubtitle =>
      'دانلود سریع‌تر با چند اتصال (aria2c باید نصب باشد)';

  @override
  String get settingsPowerTools => 'ابزارهای پیشرفته';

  @override
  String get settingsTemplates => 'الگوهای فرمان';

  @override
  String get settingsTemplatesSubtitle =>
      'مجموعه‌های ذخیره‌شده از پرچم‌های yt⁠-⁠dlp';

  @override
  String get settingsExtraArgs => 'آرگومان‌های اضافه';

  @override
  String get settingsExtraArgsEmpty => 'به هر دانلود اضافه می‌شود';

  @override
  String get settingsExtraArgsHelper =>
      'پرچم‌های خام yt⁠-⁠dlp، مثلاً --no-part --geo-bypass';

  @override
  String get settingsComponents => 'اجزا';

  @override
  String get settingsNightly => 'نسخه‌ی شبانه‌ی yt⁠-⁠dlp';

  @override
  String get settingsNightlySubtitle =>
      'رفع مشکل سایت‌ها زودتر از همه اینجا می‌رسد';

  @override
  String get settingsAbout => 'درباره';

  @override
  String get settingsAboutLicense => 'رایگان و متن‌باز، GPL-3.0';

  @override
  String get settingsSourceCode => 'کد منبع';

  @override
  String get settingsReportProblem => 'گزارش مشکل';

  @override
  String get settingsPoweredBy => 'با قدرت yt⁠-⁠dlp';

  @override
  String get settingsPoweredBySubtitle => 'قهرمان واقعی. به آن ستاره بدهید.';

  @override
  String get settingsLicenses => 'مجوزهای متن‌باز';

  @override
  String get settingsLegal =>
      'لطفاً فقط چیزی را دانلود کنید که حق دانلودش را دارید.';

  @override
  String get componentInstall => 'نصب';

  @override
  String get componentUpdate => 'به‌روزرسانی';

  @override
  String get componentChecking => 'در حال بررسی...';

  @override
  String get componentUnavailable => 'در دسترس نیست';

  @override
  String componentNotInstalled(String purpose) {
    return 'نصب نشده · $purpose';
  }

  @override
  String get componentUnknownVersion => 'نسخه‌ی نامشخص';

  @override
  String componentManaged(String app) {
    return 'مدیریت‌شده توسط $app';
  }

  @override
  String componentInstalledBy(String app) {
    return 'نصب‌شده توسط $app';
  }

  @override
  String get componentFromSystem => 'از سیستم شما';

  @override
  String get componentFoundOnSystem => 'روی سیستم شما پیدا شد';

  @override
  String componentCustom(String path) {
    return 'مسیر دلخواه: $path';
  }

  @override
  String get componentUseCustom => 'استفاده از فایل اجرایی دلخواه...';

  @override
  String get componentStopCustom => 'کنار گذاشتن مسیر دلخواه';

  @override
  String componentChooseExecutable(String tool) {
    return 'فایل اجرایی $tool را انتخاب کنید';
  }

  @override
  String get componentInstallFailed =>
      'کار تمام نشد: اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.';

  @override
  String get componentInstalled => 'نصب شد';

  @override
  String componentUpdated(String version) {
    return 'به نسخه‌ی $version به‌روز شد';
  }

  @override
  String componentUpToDate(String version) {
    return 'به‌روز است ($version)';
  }

  @override
  String componentFailed(String error) {
    return 'ناموفق: $error';
  }

  @override
  String get componentRecommended => 'پیشنهادی';

  @override
  String get purposeYtDlp => 'موتور دانلود. ضروری است.';

  @override
  String get purposeFfmpeg => 'ویدیو و صدا را ادغام و فرمت‌ها را تبدیل می‌کند.';

  @override
  String get purposeDeno => 'محیط اجرای جاوااسکریپت که یوتیوب حالا لازم دارد.';

  @override
  String get installStarting => 'در حال شروع';

  @override
  String get installDownloading => 'در حال دانلود';

  @override
  String get installUnpacking => 'در حال باز کردن';

  @override
  String get installUpdating => 'در حال به‌روزرسانی';

  @override
  String installProgress(String stage, String percent) {
    return '$stage $percent';
  }

  @override
  String componentStaleSystem(String version, String app) {
    return 'نسخه‌ی $version روی سیستم شما پیدا شد. $app نسخه‌ی به‌روز خودش را نگه می‌دارد.';
  }

  @override
  String supportTitle(String app) {
    return 'کمک کنید $app رایگان بماند';
  }

  @override
  String supportBody(String app) {
    return '$app نه تبلیغ دارد، نه ردیابی و نه نسخه‌ی پولی، و هیچ‌وقت هم نخواهد داشت. اگر وقتتان را صرفه‌جویی کرده، یک کمک کوچک باعث می‌شود به‌روزرسانی‌ها ادامه پیدا کند.';
  }

  @override
  String get supportSponsors => 'حمایت در گیت‌هاب';

  @override
  String get supportStar => 'ستاره در گیت‌هاب';

  @override
  String get templatesTitle => 'الگوهای فرمان';

  @override
  String get templatesNew => 'الگوی جدید';

  @override
  String get templatesEmptyTitle => 'هنوز الگویی ندارید';

  @override
  String get templatesEmptyBody =>
      'پرچم‌های yt⁠-⁠dlp که زیاد استفاده می‌کنید را ذخیره کنید و هنگام دانلود از «گزینه‌های بیشتر» انتخابشان کنید.';

  @override
  String get templatesCreate => 'ساختن الگو';

  @override
  String get templatesDelete => 'حذف الگو';

  @override
  String get templatesDeleted => 'الگو حذف شد';

  @override
  String get templatesEdit => 'ویرایش الگو';

  @override
  String get templatesName => 'نام';

  @override
  String get templatesNameError => 'نامی بگذارید که بعداً بشناسید';

  @override
  String get templatesFlags => 'پرچم‌های yt⁠-⁠dlp';

  @override
  String get templatesFlagsError => 'دست‌کم یک پرچم yt⁠-⁠dlp اضافه کنید';

  @override
  String get templatesNoLink => 'لینک را ننویسید؛ خودکار اضافه می‌شود';

  @override
  String get templatesFlagsHelper =>
      'پوشه‌ی خروجی، پیشرفت دانلود و لینک خودکار اضافه می‌شوند.';

  @override
  String get templatesSave => 'ذخیره‌ی الگو';

  @override
  String setupWelcome(String app) {
    return 'به $app خوش آمدید';
  }

  @override
  String setupBodyDesktop(String app) {
    return '$app با yt⁠-⁠dlp کار می‌کند، موتور متن‌بازی که پشت بیشتر دانلودرهای خوب است. بیایید ابزارهای لازم را دریافت کنیم. همه‌شان داخل پوشه‌ی خود $app می‌مانند و چیزی روی سیستم نصب نمی‌شود.';
  }

  @override
  String setupBodyAndroid(String app) {
    return 'هر چه $app لازم دارد داخل خودش است. فقط دو کار کوچک مانده.';
  }

  @override
  String get setupGetReady => 'همه‌چیز را آماده کن';

  @override
  String get setupWorking => 'در حال آماده‌سازی...';

  @override
  String get setupSkipOptional => 'رد کردن موارد اختیاری';

  @override
  String get setupStart => 'شروع کنیم';

  @override
  String get setupEngine => 'موتور دانلود';

  @override
  String setupEngineBuiltIn(String version) {
    return 'yt⁠-⁠dlp نسخه‌ی $version · داخلی';
  }

  @override
  String get setupUpdateEngine => 'به‌روزرسانی به آخرین نسخه‌ی yt⁠-⁠dlp';

  @override
  String get setupUpdateEngineSubtitle =>
      'سایت‌ها مدام تغییر می‌کنند و موتور به‌روز بیشتر مشکلات را حل می‌کند.';

  @override
  String get setupNotifications => 'نمایش پیشرفت دانلود';

  @override
  String get setupNotificationsSubtitle =>
      'یک اعلان آرام وقتی دانلودها در پس‌زمینه اجرا می‌شوند.';

  @override
  String get setupAllowed => 'مجاز شد';

  @override
  String get setupLanguage => 'زبان';

  @override
  String get setupStorage => 'ذخیره در پوشه‌ی دانلودها';

  @override
  String get setupStorageSubtitle =>
      'این نسخه از اندروید پیش از ذخیره‌ی فایل در آنجا از شما اجازه می‌گیرد.';

  @override
  String get folderAccessDenied =>
      'اجازه‌ی دسترسی به حافظه داده نشد، پس دانلودها در همان پوشه‌ی قبلی ذخیره می‌شوند.';

  @override
  String get notifyDownloading => 'در حال دانلود';

  @override
  String get supportCrypto => 'ارز دیجیتال';

  @override
  String get cryptoTitle => 'حمایت با ارز دیجیتال';

  @override
  String get cryptoBody =>
      'به ترتیب کمترین کارمزد. فقط روی همان شبکه‌ای که نوشته شده بفرستید: ارزی که روی شبکه‌ی دیگری فرستاده شود ممکن است برای همیشه از دست برود.';

  @override
  String get cryptoCopy => 'کپی آدرس';

  @override
  String cryptoCopied(String network) {
    return 'آدرس $network کپی شد';
  }

  @override
  String get cryptoLowestFees => 'کمترین کارمزد';

  @override
  String cryptoNetworkLabel(String label) {
    return 'هنگام برداشت این شبکه را انتخاب کنید: $label';
  }

  @override
  String get folderNotAllowedTitle =>
      'پوشه‌ای داخل Download یا Documents انتخاب کنید';

  @override
  String folderNotAllowedBody(String folder) {
    return 'اندروید به برنامه‌ها اجازه می‌دهد فقط در Download یا Documents (یا پوشه‌های داخل آن‌ها) فایل ذخیره کنند. $folder بیرون از این‌هاست، پس دانلود در آنجا ناموفق می‌شود.';
  }

  @override
  String get folderNotAllowedOk => 'انتخاب پوشه‌ی دیگر';
}
