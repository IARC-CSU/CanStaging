# Changelog CanStaging<sup>+</sup>

## 0.8.15 (2021-07-02)

- Implemented a tool to test consistency of the business logic.
- CI-related work.
- Bugfixes.

## 0.8.14 (2021-06-15)

- Bugfixes.

## 0.8.13 (2021-06-04)

- Tidied and renamed files in the standalone install to avoid confusion.
- Updated eTNM Cervix.
- Bugfixes.

## 0.8.11 (2021-06-02)

- Bugfixes.

## 0.8.10 (2021-06-01)

- "T2","N0","M0" -> "IB" corrected.
- Bugfixes.

## 0.8.9 (2021-05-27)

- Bugfixes.

## 0.8.8 (2021-05-26)

- Images (and PDFs) can now be associated with the cancer site itself to enable pop ups with more information.
- Added padding to html pop-ups.

## 0.8.6 (2021-05-18)

- Remove 'capitalization' of site names.
- Sites can now have a popup text for general instructions.
- Added GRELL logo
- Other fixes.

## 0.8.5 (2021-05-03)

- Updated eTNM cervix flowcharts.
- Centralized the staging system translations.
- Added UKIACR logo and link.
- Added staging system chooser on first load.
- Tidied landing page(s).
- Fixed bug in txt field for sites.
- Default port changed to default Sinatra's 4567.
- Other bugfixes.

## 0.8.4 (2021-04-28)

- Bugfixes.

## 0.8.3 (2021-04-12)

- Hide 'Upload' button when not logged in.
- Minor text tweaks.

## 0.8.2 (2021-04-09)

- Added feedback form.
- Added a usage tracker.
- Minor bug fixes.

## 0.8.1 (2021-02-24)

- Disable get log when not logged in.
- Added Melanoma SG tests text.
- Clear TNM result while waiting for new data to avoid sync issues.
- Various bug fixes.

## 0.8.0 (2021-01-26)

- User no longer need a key to use the tool.
	- User can not submit cases to their database without being logged in.
	- Default key is used while in standalone mode.

## 0.7.3 (2021-01-25)

- Updated rules on some sites.
- Fixed typos.
- Other fixes.

## 0.7.2 (2021-01-08)

- Images updated for V8 Lung, Pancreas, Cervix, Colorectal.
- Better handling of missing staging system. (To allow Toronto-guidelines.)
- Disabled collapse of T, N, M parts of form.
- Description text of Lung T added.
- Added support for Markdown in DisplayText field of form.
- Better cropping of some images.
- Fixed some table issues:
	- Prostate SimpG
	- Removed "Don't know" for Breast P V8 Micromets
	- FIGO back for TNM7.
	- Added highlighting.
- Other fixes.

## 0.7.1 (2020-12-17)

- Colorectal (under TNM7) now labeled as TNM5.
- Other fixes.

## 0.7.0 (2020-12-16)
- Updated busines logic.
- Fixed the bug where the ordering of fields on the forms sometimes was wrong.
- Stability improvements.

## 0.6.9 (2020-12-03)

- Improved 'Don't know' algorithm.
- Registration form added.
- Cosmetic changes.

## 0.6.8 (2020-10-20)

- Improved handling of write protected/missing log folder.
- CanStaging+ is now CanStaging<sup>+</sup>.

## 0.6.7 (2020-10-14)

- About text updated.
- Tidied up the login-page.
- Added a log in menu item and made login screen clearer.
- You no longer need to log in before the staging form itself.
- Language menu removed -- for now.
- CanStaging is now CanStaging+
- Issues in Breast tables resolved.
- Issues in Breast images resolved.
- Updated help file.
- Other fixes.

## 0.6.6 (2020-09-09)

- Welcome text updated.
- Help doc updated.
- Logos updated.
- Default to TNM8.

## 0.6.5 (2020-08-31)

- Fall back to in-memory database if no other options.
- Only show "TNM with Prefixes" on v7.
- Updated batch data uploader to, for example, work with with TNM versions.
- Demo version implemented.

## 0.6.4 (2020-07-03)

- Breast, Cervix, Ovary, Prostate, Lung, and Oesophagus images updated.
- Framework for the system of pop up texts/lists in place.
- Melanoma now split in clinical/pathological.
- Fixed issues with Oesophagus tables.
- Some spelling errors fixed.

## 0.6.3 (2020-06-15)

- Illustrations now show up on click instead of hover.

## 0.6.2 (2020-06-12)

- Melanoma added.
- Colors harmonized with GCO colors.
- Landing page now has a card based layout.
- Illustrations now only pops up when hovering eye icon.
- Breast images added.
- Upgraded to FontAwesome 5.
- Other fixes.

## 0.6.1 (2020-05-29)

- Changed to the amalgalite gem for sqlite access.

## 0.6.0 (2020-05-27)

- Ruby changed from 2.4 to 2.6.
- Web server changed from Thin to Puma.
- All gems are the latest version.
- Lung images added.
- Oesophagus images updated.

## 0.5.9 (2020-05-25)

- Changelog is now dynamically read by the tool.

## 0.5.8 (2020-05-25)

- Added images for Prostate and Cervix.
- About moved to a page instead of pop-up.

## 0.5.7 (2020-05-05)

- Installer generator automatically signs installer.
- Generate changelog.html automatically in build script.

## 0.5.5 (2020-04-27)

- Fixed bug where server didn't launch in stand alone mode if home dir was not accessible...

## 0.5.4 (2020-04-21)

- 'Invalid combination instead of ERROR'
- Improved password page

## 0.5.2 (2020-04-03)

- Regrouped Oesophagus into one table.
- Defaults read from first entry in table without Xs
- Removed all Xs lines from tables
- Modified v7 tables to accomodate defaults.
- Configuration files work.
    - Default config in data folder.
    - Override in user folder (.canstaging) for added security.
- Users can now shut down the standalone tool from their browser.
- Default credentials if keyfile is missing.
- Launcher icon added.
- Updated translations and improved error messages.
- Improved layout of forms.
- Added TNM version to DB and logs.
- Version numbering in setup file.
- Updated Docker install.
- Fixed sorting of questions
- Fixed error when deploying due to difference in Ruby version.
- Other bug fixes.

## 0.4.0 (2020-03-30)

- Images and PDFs for Essential TNM added.

## 0.3.0 (2020-03-12)

- Handle "don't knows".
- TNM version explicit on the site selection screen and forms.
- Prepared tables for Xs for missing data.

## 0.2.0 (2020-02-03)

- Images added for Stomach, Liver, Oesophagus, Pancreas, Colorectal and Ovary.