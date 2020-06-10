# Changelog CanStaging

## 0.6.2 (TBD)

- Melanoma added.
- Colors harmonized with GCO colors.
- Landing page now has a card based layout.
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