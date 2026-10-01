# Work Sans font source

Work Sans is the approved sole font family for The Data Decoded. These three unmodified static TTF files and `OFL.txt` come from the official [Work Sans repository](https://github.com/weiweihuanghuang/Work-Sans), release **v2.010**, commit [`6634e7b2395e9dba4ac8611c4529968a9719d606`](https://github.com/weiweihuanghuang/Work-Sans/commit/6634e7b2395e9dba4ac8611c4529968a9719d606), under `fonts/static/TTF/`. The upstream copyright notice is in `OFL.txt` beside the fonts. The license is SIL Open Font License 1.1; keep the notice and license with redistributed copies. Do not sell font files by themselves or relicense modified versions.

| File | SHA-256 |
| --- | --- |
| `WorkSans-Regular.ttf` | `22E7F1607EBC29D03BE61D893EC47DDE307847EAF60FBEC260E286695001982A` |
| `WorkSans-Medium.ttf` | `3C5AE1EF9260A0C1CDF1F59841F28620C40826F6CA3BD4C71516997C29FEC7DC` |
| `WorkSans-Bold.ttf` | `E5C36B1191BE27046270DA352F231FC342AD4333CFB2967F393E00D18C274CDC` |
| `OFL.txt` | `749ACA05078664CE682DCE1B1B10096AC397CB088C1A6DF4E1BB56F0092A9272` |

The local HTML preview uses these TTFs through `@font-face`. The exploratory R script registers these exact file paths with `systemfonts` and aborts if they are absent or cannot be resolved; a Windows-wide font installation is not required for that script. To use Work Sans in other RStudio sessions, select the TTFs in File Explorer, right-click **Install for all users** (administrator access may be requested) or **Install** for your Windows user, then restart RStudio and confirm the Regular, Medium, and Bold faces with `systemfonts::font_info()` or `systemfonts::match_fonts()`. Do not install or commit Georgia; its earlier comparison is archived separately.
