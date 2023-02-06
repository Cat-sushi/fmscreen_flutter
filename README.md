# FMScreen_Flutter (JunoScreen)

## Description

This is a system of name screening against denial lists such as US EAR Entity List.

## The Web Application

[JunoScreen](https://fms.catsushi.net/)

## The Server

[FMScreen](https://github.com/Cat-sushi/fmscreen)

## The Text Matching Engine

[FMatch](https://github.com/Cat-sushi/fmatch)

## Screen Shots

![Screenshot from 2023-02-06 23-07-56](https://user-images.githubusercontent.com/10280770/216993394-45ba5106-2167-4132-b308-c39b34ce79b5.png)
![Screenshot from 2023-02-06 23-47-58](https://user-images.githubusercontent.com/10280770/217003364-40b73054-5d1a-4929-978e-381b33495d9c.png)

## Features
- Term fuzzy matching using Levenshtein distance.
- Divided query terms matching with single list term.
- Pertial terms matching.
- Disordered terms matching.
- Score based filtering respecting term similarity, term order, and term importance of IDF.
- Exact matching mode disabling fuzzy matchings for reducing false positives in some cases.
- Accepting Latin characters, Chinese characters, Katakana characters, and others.
- Canonicalaization of traditioanal and simplified Chinese characters, and others.
  This makes matching insensitive to character simplification.
- Canonicalaization of spelling variants of legal entity types such as "Limitd" and "Ltd.".
  This makes matching insensitive to spelling variants of legal entity types.
- White queries for avoiding screening your company itself and consequent false positives.
- Results cache for time performance.
- Interactive Screening.
- PDF download.
- Batch Screening.
- White Results for skiping check of false positives.
- And others.

## Usage ― General ―

### Recomended Input

- Official full name is recommended.
- Discriminating keyword is OK, but too short keyword might cause massive false positives.

### Exact Matching
**Note**: Do not use exact matching for names with orthographical variants.

Embrace whole input string with double-quates.
This disables,

- Term fuzzy matching
- Pertial terms matching
- Disordered terms matching

But, keeps enable,

- Normaliztion
  - Captalization
  - White space normalization
  - Unicode normalization
- Canonicalization of traditional/ simplified Chinese characters
- Canonicalization of variants of spelling of legal entity types

In other words, only items with score of 100 will be listed out.

## Usage ― Intractive Screening ―

- "Input String" is the string you inputted.
- "Normalized" is normalized string of your input string.
- "Preprocessed" is a set of extracted "words" from preprocess.
  Preprocess includes canonicalization of traditional/ simplified Chinese characters,
  canonicalization of variants of spelling of legal entyty types, and others.
- "Query Score" means the discrimination of input strings. 
  Input strings with low query score might cause massive false positives,
  while high query score does not necessarily mean a good input string.
- "Start" means Date/Time of starting the screening.
- "Duration" means the internal hold time in seconds in the server for screening.
- "DB Ver.", database version, means the Date/Time when the database from Denial Lists is created.
  The difference of database version donesn't necesarilly mean some of Denial Lists are modifined.
- "Server ID" is just for your information. This is the thread (Dart Isolate) ID in the server.
- "Exact" is checked when the input string is embraced with double-quates.
- "Fallen Back" is cheked when some termes of preprocessed are removed for some peformance reasons,
  in some very rare cases.
- "Message" is the message from the server. It's just for your information.
- The left pain contains the best matched name of each detected item of Denial Lists,
  with matching score and the code of list.
- The right pain contains the details of each detected item.
- Click a detected item in the left pain to scroll the right pain to the details of the item,
  and vice-versa.
- Click [Get PDF] button to obtain detected items list in PDF format.
  The PDF file doesn't contain the details of the items.

## Usage ― Batch Screening ―
### UI

- Make a name list for screening in CSV format with name of "names.csv".
- Click [Select Batch Directory] button.
- With opened file picker, select the directory containing the "names.csv".
- "results.csv" and "log.txt" will be placed in the same directory.

### Name List Format

"names.csv" is in CSV  format.

|Column|Description|
|---|---|
|1st|Every one line contains one name for screening.|
|2nd|You can optionally specify a transaction ID for each line. See "White Results" section.|

### Results Format

"results.csv" is in CSV format.

|Column|Description|
|---|---|
|1st|The number of the row in "names.csv"|
|2nd|The transaction ID. See the "White Results" section.|
|3rd|The name for screening. Normalized.|
|4th|The matching score.|
|5th|The code of list|
|6th|The best matched name of each detected item. Normalized.|
|7th|The flag of checked. See the "White Results" section.|
|8th|The Date/Time of screening.|
|9th|The version of the database made from the Denial Lists.|
|10th|The Date/Time of the first detection of the item with same name for screening, transaction ID, code of list, and best matched name of detected item. See the "White Results" section.|

### White Results

White Results are useful to skip redundant checks for false positives.

A file of results from previous batch screening can be used as White Reults with following steps,

- Rename "results.csv" to "white_results.csv"
- Turn the 7th (the flag of checked) column from "false" to "true"
- Place the "white_results.csv" at same directory of "names.csv"
- Kick the next batch screening.

Each detected item which is already listed in White Results with same name for screening, transaction ID,
code of list, and best matched name of the item will be marked "true" in 7th column,
and the 10th (the Date/Time of first detect) column will be copied from that of the item in the White Results.

## Contained Denial Lists

|List Name|Code of Denial List|
|---|---|
|Capta List (CAP) - Treasury Department|CAP|
|Denied Persons List (DPL) - Bureau of Industry and Security|DPL|
|Entity List (EL) - Bureau of Industry and Security|EL|
|Foreign Sanctions Evaders (FSE) - Treasury Department|FSE|
|ITAR Debarred (DTC) - State Department|DTC|
|Military End User (MEU) List - Bureau of Industry and Security|MEU|
|Non-SDN Chinese Military-Industrial Complex Companies List (CMIC) - Treasury Department|CMIC|
|Non-SDN Menu-Based Sanctions List (NS-MBS List) - Treasury Department|MBS|
|Nonproliferation Sanctions (ISN) - State Department|ISN|
|Sectoral Sanctions Identifications List (SSI) - Treasury Department|SSI|
|Specially Designated Nationals (SDN) - Treasury Department|SDN|
|Unverified List (UVL) - Bureau of Industry and Security|UVL|
|Foreigh End User List (EUL) - Ministry of Economy, Trade and Industry, Japan|EUL|

### Renewal

Denial Lists are downloaded every 6 hours, and if some of them are changed, the database will be renewed and
the result cache will be purged.

### Sources

- [Consolidated Screening List](https://www.trade.gov/consolidated-screening-list "Consolidated Screening List")
- [安全保障貿易管理**Export Control*関係法令：申請、相談に関する通達](https://www.meti.go.jp/policy/anpo/law05.html "安全保障貿易管理**Export Control*関係法令：申請、相談に関する通達")

## License

### This Web Client

MITL

### The Server

AGPL3.0

Contact me if you need another different License.

### Dependences

Libraries used by this system have their own OSS Licenses.

### Denial Lists

Public Domain
