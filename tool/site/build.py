#!/usr/bin/env python3
"""Builds the Snag website (GitHub Pages, served from docs/).

    python3 tool/site/build.py

One template, two languages, so the English and Persian pages never drift.
Writes docs/index.html, docs/fa/index.html, docs/sitemap.xml,
docs/robots.txt and docs/.nojekyll. Wallets come from lib/core/app_info.dart
so the site, the app and the READMEs always show the same addresses.
"""
import json
import re
from datetime import date
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
ICONS = DOCS / "site" / "icons"
BASE = "https://salehtz.github.io/snag/"
REPO = "https://github.com/SalehTZ/snag"
RELEASES = f"{REPO}/releases/latest"
LATEST = f"{RELEASES}/download"


def icon(name: str, extra: str = "") -> str:
    svg = (ICONS / f"{name}.svg").read_text().strip()
    return svg.replace("<svg ", f'<svg class="icon {extra}" aria-hidden="true" ', 1)


def wallets() -> list[dict]:
    """Parses the Wallet(...) entries from app_info.dart (single source)."""
    src = (ROOT / "lib/core/app_info.dart").read_text()
    out = []
    for block in re.findall(r"Wallet\((.*?)\),", src, re.S):
        fields = dict(re.findall(r"(\w+):\s*'([^']*)'", block))
        if {"network", "label", "coins", "address"} <= fields.keys():
            out.append(fields)
    assert len(out) >= 4, "could not read wallets from app_info.dart"
    return out


T = {
    "en": {
        "dir": "ltr",
        "path": "",
        "title": "Snag: Free Open Source Video Downloader for Android and PC",
        "desc": "Paste a link, get the file. Snag downloads video and audio from YouTube, Instagram, TikTok and over a thousand sites. Free, open source, no ads.",
        "nav": ["Features", "Download", "Support", "FAQ"],
        "lang_link": ("فارسی", "fa/"),
        "h1": "Paste a link. Get the file.",
        "sub": "Snag is a free, open source video and audio downloader for Android, Windows, macOS and Linux. No ads, no tracking.",
        "cta": "Download",
        "cta2": "Source code",
        "alt_desktop": "Snag on a desktop computer, ready for a link",
        "alt_phone": "Snag on an Android phone",
        "f_h": "Simple on the surface. Powerful underneath.",
        "f_lead": "Snag runs on yt-dlp, the open source engine behind most good downloaders, and works with well over a thousand sites.",
        "f": [
            ("lightning", "One box, one button", "Paste a link or drop it on the window. Snag even spots links you've already copied.", "alt_sheet"),
            ("film-strip", "Video or just the audio", "Pick a quality up to 4K, or save MP3, M4A, Opus or FLAC."),
            ("list-checks", "Whole playlists", "Choose exactly which items to grab, then let the queue do the rest."),
            ("translate", "Speaks your language", "English and فارسی built in, with right-to-left layout and the Persian calendar. More languages come from the community.", "alt_fa"),
            ("shield-check", "Yours, not ours", "No ads, no tracking, no accounts. Your downloads never leave your device."),
        ],
        "alt_sheet": "Choosing quality before a download",
        "alt_fa": "Snag in Persian",
        "d_h": "Get Snag",
        "d_lead": "Free on every platform. On desktop, Snag fetches the official yt-dlp and ffmpeg on first run, inside its own folder.",
        "platforms": [
            ("android-logo", "Android", "Android 7 or newer, most phones", "snag-android-arm64-v8a.apk"),
            ("windows-logo", "Windows", "Windows 10 and 11, 64-bit", "snag-windows-x64.zip"),
            ("apple-logo", "macOS", "Apple silicon and Intel", "snag-macos.zip"),
            ("linux-logo", "Linux", "64-bit, extract and run", "snag-linux-x64.tar.gz"),
        ],
        "get": "Download",
        "older": "Older Android phone? Get the armeabi-v7a build from",
        "all_releases": "all releases",
        "verify": "Every release is signed with the same key, so you can check that an APK really comes from us.",
        "verify_link": "How to verify",
        "e_h": "Built on yt-dlp",
        "e_p": "Sites change all the time. Snag updates its engine with one tap, so most broken downloads are fixed within days, not months.",
        "e_cta": "Star yt-dlp on GitHub",
        "s_h": "Keep Snag free",
        "s_p": "Snag has no ads, no tracking and no paywall, and it never will. If it saved you some time, a small donation keeps updates coming.",
        "s_sponsor": "GitHub Sponsors",
        "s_note": "Listed cheapest first. Send only on the network shown.",
        "s_pick": "On exchanges, pick",
        "s_low": "Lowest fees",
        "s_copy": "Copy address",
        "faq_h": "Questions",
        "faq": [
            ("Is Snag really free?", "Yes. Snag is open source under the GPL-3.0 license, with no ads, no tracking, no accounts and no paid version. Donations keep development going."),
            ("Which sites does it support?", "Anything yt-dlp supports, including YouTube, Instagram, TikTok, X, Facebook, SoundCloud, Vimeo, Twitch, Reddit and well over a thousand more."),
            ("Android warns me before installing. Is it safe?", "Snag isn't on Google Play yet, so Play Protect may say it hasn't seen the app before. The code is public, and every release is signed with the same key, which you can verify."),
            ("Is there an iPhone version?", "No. iOS doesn't allow apps to run yt-dlp. Snag runs on Android, Windows, macOS and Linux."),
            ("A site stopped working. What should I do?", "Open Settings, then Components, and update yt-dlp. You can also switch on the nightly version, where fixes for broken sites land first."),
            ("Is downloading videos legal?", "It depends on the content and where you live. Only download what you have the right to, and respect each site's terms."),
        ],
        "foot_license": "Free and open source, GPL-3.0",
        "foot_links": [("GitHub", REPO), ("Report a problem", f"{REPO}/issues"), ("Translate", f"{REPO}/blob/main/TRANSLATING.md")],
    },
    "fa": {
        "dir": "rtl",
        "path": "fa/",
        "title": "Snag: دانلودر رایگان و متن‌باز ویدیو برای اندروید و کامپیوتر",
        "desc": "لینک را بچسبانید و فایل را بگیرید. Snag ویدیو و صدا را از یوتیوب، اینستاگرام، تیک‌تاک و بیش از هزار سایت دانلود می‌کند. رایگان، متن‌باز و بدون تبلیغ.",
        "nav": ["امکانات", "دانلود", "حمایت", "پرسش‌ها"],
        "lang_link": ("English", "../"),
        "h1": "لینک را بچسبانید، فایل را بگیرید.",
        "sub": "Snag یک دانلودر رایگان و متن‌باز ویدیو و صدا برای اندروید، ویندوز، مک و لینوکس است. بدون تبلیغ و ردیابی.",
        "cta": "دانلود",
        "cta2": "کد منبع",
        "alt_desktop": "Snag روی کامپیوتر، آماده‌ی دریافت لینک",
        "alt_phone": "Snag روی گوشی اندروید",
        "f_h": "ساده در ظاهر، قدرتمند در عمل.",
        "f_lead": "Snag با yt-dlp کار می‌کند، موتور متن‌بازی که پشت بیشتر دانلودرهای خوب است، و با بیش از هزار سایت سازگار است.",
        "f": [
            ("lightning", "یک جعبه، یک دکمه", "لینک را بچسبانید یا روی پنجره رها کنید. Snag لینکی را که کپی کرده‌اید خودش پیدا می‌کند.", "alt_sheet"),
            ("film-strip", "ویدیو یا فقط صدا", "کیفیت را تا 4K انتخاب کنید یا صدا را به‌صورت MP3، M4A، Opus یا FLAC ذخیره کنید."),
            ("list-checks", "پلی‌لیست کامل", "دقیقاً انتخاب کنید چه چیزهایی دانلود شود و بقیه را به صف بسپارید."),
            ("translate", "به زبان شما", "فارسی و انگلیسی داخل برنامه است، با چیدمان راست‌به‌چپ و تقویم شمسی. زبان‌های دیگر را جامعه اضافه می‌کند.", "alt_fa"),
            ("shield-check", "مال شما، نه ما", "بدون تبلیغ، بدون ردیابی، بدون حساب کاربری. فایل‌هایتان از دستگاهتان بیرون نمی‌روند."),
        ],
        "alt_sheet": "انتخاب کیفیت پیش از دانلود",
        "alt_fa": "Snag به زبان فارسی",
        "d_h": "دریافت Snag",
        "d_lead": "روی همه‌ی سیستم‌عامل‌ها رایگان است. روی دسکتاپ، Snag در اولین اجرا yt-dlp و ffmpeg رسمی را داخل پوشه‌ی خودش دریافت می‌کند.",
        "platforms": [
            ("android-logo", "اندروید", "اندروید ۷ و جدیدتر، بیشتر گوشی‌ها", "snag-android-arm64-v8a.apk"),
            ("windows-logo", "ویندوز", "ویندوز ۱۰ و ۱۱، ۶۴ بیتی", "snag-windows-x64.zip"),
            ("apple-logo", "مک", "Apple silicon و Intel", "snag-macos.zip"),
            ("linux-logo", "لینوکس", "۶۴ بیتی، از حالت فشرده خارج و اجرا کنید", "snag-linux-x64.tar.gz"),
        ],
        "get": "دانلود",
        "older": "گوشی اندروید قدیمی دارید؟ نسخه‌ی armeabi-v7a را از",
        "all_releases": "همه‌ی نسخه‌ها بگیرید",
        "verify": "همه‌ی نسخه‌ها با یک کلید امضا می‌شوند تا بتوانید مطمئن شوید APK واقعاً از ماست.",
        "verify_link": "روش بررسی",
        "e_h": "با قدرت yt-dlp",
        "e_p": "سایت‌ها مدام تغییر می‌کنند. Snag موتورش را با یک لمس به‌روز می‌کند، پس بیشتر دانلودهای خراب ظرف چند روز درست می‌شوند، نه چند ماه.",
        "e_cta": "به yt-dlp در گیت‌هاب ستاره بدهید",
        "s_h": "کمک کنید Snag رایگان بماند",
        "s_p": "Snag نه تبلیغ دارد، نه ردیابی و نه نسخه‌ی پولی، و هیچ‌وقت هم نخواهد داشت. اگر وقتتان را صرفه‌جویی کرده، یک کمک کوچک باعث می‌شود به‌روزرسانی‌ها ادامه پیدا کند.",
        "s_sponsor": "حمایت در گیت‌هاب",
        "s_note": "به ترتیب کمترین کارمزد. فقط روی همان شبکه‌ای که نوشته شده بفرستید.",
        "s_pick": "در صرافی انتخاب کنید",
        "s_low": "کمترین کارمزد",
        "s_copy": "کپی آدرس",
        "faq_h": "پرسش‌ها",
        "faq": [
            ("Snag واقعاً رایگان است؟", "بله. Snag تحت مجوز GPL-3.0 متن‌باز است و تبلیغ، ردیابی، حساب کاربری یا نسخه‌ی پولی ندارد. کمک‌های مالی باعث ادامه‌ی توسعه می‌شوند."),
            ("از چه سایت‌هایی پشتیبانی می‌کند؟", "هر سایتی که yt-dlp پشتیبانی کند، از جمله یوتیوب، اینستاگرام، تیک‌تاک، ایکس، فیسبوک، ساندکلاد، ویمیو، توییچ، ردیت و بیش از هزار سایت دیگر."),
            ("اندروید پیش از نصب هشدار می‌دهد. امن است؟", "Snag هنوز در گوگل‌پلی نیست، پس Play Protect ممکن است بگوید این برنامه را قبلاً ندیده است. کد آن عمومی است و همه‌ی نسخه‌ها با یک کلید امضا می‌شوند که می‌توانید بررسی‌اش کنید."),
            ("نسخه‌ی آیفون دارد؟", "نه. iOS به برنامه‌ها اجازه‌ی اجرای yt-dlp نمی‌دهد. Snag روی اندروید، ویندوز، مک و لینوکس کار می‌کند."),
            ("سایتی دیگر کار نمی‌کند. چه کنم؟", "به تنظیمات، بخش اجزا بروید و yt-dlp را به‌روز کنید. می‌توانید نسخه‌ی شبانه را هم روشن کنید که رفع مشکل سایت‌ها زودتر از همه در آن می‌رسد."),
            ("دانلود ویدیو قانونی است؟", "به محتوا و محل زندگی شما بستگی دارد. فقط چیزی را دانلود کنید که حق دانلودش را دارید و به قوانین هر سایت احترام بگذارید."),
        ],
        "foot_license": "رایگان و متن‌باز، GPL-3.0",
        "foot_links": [("گیت‌هاب", REPO), ("گزارش مشکل", f"{REPO}/issues"), ("ترجمه", f"{REPO}/blob/main/TRANSLATING.md")],
    },
}


def picture(light: str, dark: str | None, alt: str, cls: str, up: str, width: int, height: int, eager=False) -> str:
    src = f"{up}site/img/{light}.webp"
    dark_src = f'<source srcset="{up}site/img/{dark}.webp" media="(prefers-color-scheme: dark)">' if dark else ""
    # Above the fold: fetch first and decode before first paint.
    loading = ('fetchpriority="high" decoding="sync"' if eager
               else 'loading="lazy" decoding="async"')
    return (f'<picture>{dark_src}<img class="{cls}" src="{src}" alt="{escape(alt)}" '
            f'width="{width}" height="{height}" {loading}></picture>')


def page(lang: str) -> str:
    t = T[lang]
    up = "../" if t["path"] else ""
    url = BASE + t["path"]
    fa = lang == "fa"
    w = wallets()

    ld_app = {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "name": "Snag",
        "description": t["desc"],
        "url": url,
        "image": BASE + "site/icon-512.png",
        "screenshot": BASE + "site/img/home_phone_light.webp",
        "applicationCategory": "MultimediaApplication",
        "operatingSystem": "Android, Windows, macOS, Linux",
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "license": "https://www.gnu.org/licenses/gpl-3.0.html",
        "downloadUrl": RELEASES,
        "codeRepository": REPO,
        "inLanguage": ["en", "fa"],
    }
    ld_faq = {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}}
            for q, a in t["faq"]
        ],
    }

    nav_ids = ["features", "download", "support", "faq"]
    nav = "".join(
        f'<a class="hide-sm" href="#{i}">{escape(n)}</a>' for i, n in zip(nav_ids, t["nav"])
    )
    lang_name, lang_href = t["lang_link"]

    # Features: exactly five cells in an uneven grid.
    cells = []
    for i, f in enumerate(t["f"]):
        name, h, p = f[0], f[1], f[2]
        head = f'<div class="ic">{icon(name)}</div><h3>{escape(h)}</h3><p>{escape(p)}</p>'
        if i == 0:
            shot = picture("sheet_phone_light" if not fa else "fa_sheet_phone",
                           "sheet_phone_dark" if not fa else None,
                           t[f[3]], "", up, 560, 1213)
            cells.append(f'<article class="cell cell-main">{head}{shot}</article>')
        elif i == 1:
            cells.append(f'<article class="cell cell-brand">{head}</article>')
        elif i == 2:
            cells.append(f'<article class="cell">{head}</article>')
        elif i == 3:
            shot = picture("fa_home_phone", None, t[f[3]], "", up, 560, 1213)
            cells.append(f'<article class="cell cell-wide"><div>{head}</div>{shot}</article>')
        else:
            cells.append(f'<article class="cell cell-full"><div class="ic">{icon(name)}</div>'
                         f'<div><h3>{escape(h)}</h3><p>{escape(p)}</p></div></article>')

    platforms = "".join(
        f'<div class="platform">{icon(ic)}<div class="info"><strong>{escape(n)}</strong>'
        f'<small>{escape(d)}</small></div>'
        f'<a class="btn btn-ghost" href="{LATEST}/{file}">{icon("download-simple")}{escape(t["get"])}</a></div>'
        for ic, n, d, file in t["platforms"]
    )

    wallet_rows = "".join(
        f'<div class="wallet"><div class="net">{escape(x["network"])}'
        + (f'<span class="pill">{escape(t["s_low"])}</span>' if i == 0 else "")
        + f'</div><div class="pick">{escape(t["s_pick"])}: <span class="ltr">{escape(x["label"])}</span></div>'
        f'<code>{escape(x["address"])}</code>'
        f'<button class="copy" type="button" data-copy="{escape(x["address"])}" aria-label="{escape(t["s_copy"])}: {escape(x["network"])}">'
        f'<span class="todo">{icon("copy")}</span><span class="done">{icon("check")}</span></button></div>'
        for i, x in enumerate(w)
    )

    faq = "".join(
        f"<details><summary>{escape(q)}</summary><p>{escape(a)}</p></details>" for q, a in t["faq"]
    )
    foot_links = "".join(f'<a href="{h}">{escape(n)}</a>' for n, h in t["foot_links"])

    return f"""<!doctype html>
<html lang="{lang}" dir="{t['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{escape(t['title'])}</title>
<meta name="description" content="{escape(t['desc'])}">
<link rel="canonical" href="{url}">
<link rel="alternate" hreflang="en" href="{BASE}">
<link rel="alternate" hreflang="fa" href="{BASE}fa/">
<link rel="alternate" hreflang="x-default" href="{BASE}">
<meta name="theme-color" content="#6b2cf5">
<link rel="icon" type="image/png" sizes="32x32" href="{up}site/favicon-32.png">
<link rel="apple-touch-icon" href="{up}site/apple-touch-icon.png">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Snag">
<meta property="og:title" content="{escape(t['title'])}">
<meta property="og:description" content="{escape(t['desc'])}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{BASE}site/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="{'fa_IR' if fa else 'en_US'}">
<meta name="twitter:card" content="summary_large_image">
<link rel="preload" href="{up}site/fonts/{'Vazirmatn-Bold' if fa else 'Figtree-ExtraBold'}.ttf" as="font" type="font/ttf" crossorigin>
<link rel="stylesheet" href="{up}site/style.css">
<script type="application/ld+json">{json.dumps(ld_app, ensure_ascii=False)}</script>
<script type="application/ld+json">{json.dumps(ld_faq, ensure_ascii=False)}</script>
</head>
<body>
<header class="nav"><div class="wrap">
  <a class="brand" href="{up or './'}"><img src="{up}site/favicon-32.png" srcset="{up}site/icon-512.png 2x" alt="" width="34" height="34">Snag</a>
  <nav class="nav-links">{nav}<a class="lang" href="{lang_href}" hreflang="{'en' if fa else 'fa'}" lang="{'en' if fa else 'fa'}">{lang_name}</a>
  <a href="{REPO}" aria-label="GitHub">{icon('github-logo')}</a></nav>
</div></header>

<main>
<section class="hero"><div class="wrap">
  <div>
    <h1 class="rise">{escape(t['h1'])}</h1>
    <p class="rise rise-2">{escape(t['sub'])}</p>
    <div class="ctas rise rise-3">
      <a class="btn btn-primary" href="#download">{icon('download-simple')}{escape(t['cta'])}</a>
      <a class="btn btn-ghost" href="{REPO}">{icon('github-logo')}{escape(t['cta2'])}</a>
    </div>
  </div>
  <div class="shots rise rise-2">
    {picture('fa_home_desktop_dark' if fa else 'home_desktop_light', None if fa else 'home_desktop_dark', t['alt_desktop'], 'desktop', up, 1400, 933, eager=True)}
    {picture('fa_home_phone' if fa else 'home_phone_light', None if fa else 'home_phone_dark', t['alt_phone'], 'phone', up, 560, 1213, eager=True)}
  </div>
</div></section>

<section id="features"><div class="wrap">
  <h2>{escape(t['f_h'])}</h2>
  <p class="lead">{escape(t['f_lead'])}</p>
  <div class="bento">{''.join(cells)}</div>
</div></section>

<section id="download"><div class="wrap">
  <h2>{escape(t['d_h'])}</h2>
  <p class="lead">{escape(t['d_lead'])}</p>
  <div class="platforms">{platforms}</div>
  <p class="note">{icon('seal-check')}<span>{escape(t['older'])} <a href="{RELEASES}">{escape(t['all_releases'])}</a>. {escape(t['verify'])} <a href="{REPO}#readme">{escape(t['verify_link'])}</a></span></p>
</div></section>

<section class="engine"><div class="wrap">
  <h2>{escape(t['e_h'])}</h2>
  <p>{escape(t['e_p'])}</p>
  <a class="btn btn-ghost" href="https://github.com/yt-dlp/yt-dlp">{icon('heart')}{escape(t['e_cta'])}</a>
</div></section>

<section id="support" class="support"><div class="wrap">
  <div>
    <h2>{escape(t['s_h'])}</h2>
    <p class="lead">{escape(t['s_p'])}</p>
    <a class="btn btn-primary" href="https://github.com/sponsors/SalehTZ">{icon('heart')}{escape(t['s_sponsor'])}</a>
  </div>
  <div>
    <p class="note" style="margin-top:0">{escape(t['s_note'])}</p>
    <div class="wallets">{wallet_rows}</div>
  </div>
</div></section>

<section id="faq" class="faq"><div class="wrap">
  <h2>{escape(t['faq_h'])}</h2>
  {faq}
</div></section>
</main>

<footer><div class="wrap">
  <span>Snag · {escape(t['foot_license'])}</span>
  <nav>{foot_links}</nav>
</div></footer>

<script>
document.querySelectorAll("[data-copy]").forEach((b) => b.addEventListener("click", async () => {{
  try {{ await navigator.clipboard.writeText(b.dataset.copy); }} catch (_) {{ return; }}
  b.classList.add("copied");
  setTimeout(() => b.classList.remove("copied"), 1600);
}}));
</script>
</body>
</html>
"""


def main() -> None:
    (DOCS / "index.html").write_text(page("en"))
    (DOCS / "fa").mkdir(exist_ok=True)
    (DOCS / "fa" / "index.html").write_text(page("fa"))
    today = date.today().isoformat()
    (DOCS / "sitemap.xml").write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url><loc>{BASE}</loc><lastmod>{today}</lastmod>
    <xhtml:link rel="alternate" hreflang="fa" href="{BASE}fa/"/>
    <xhtml:link rel="alternate" hreflang="en" href="{BASE}"/></url>
  <url><loc>{BASE}fa/</loc><lastmod>{today}</lastmod>
    <xhtml:link rel="alternate" hreflang="en" href="{BASE}"/>
    <xhtml:link rel="alternate" hreflang="fa" href="{BASE}fa/"/></url>
</urlset>
""")
    (DOCS / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {BASE}sitemap.xml\n")
    (DOCS / ".nojekyll").write_text("")
    print("built docs/index.html, docs/fa/index.html, sitemap.xml, robots.txt")


if __name__ == "__main__":
    main()
