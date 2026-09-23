# Raw inputs

The original files that the tidy data in [`data/`](../data) is built from,
kept byte for byte as they were committed, and the script that builds it.
Nothing else reads these files.

| File | Contents | Read by |
|---|---|---|
| [`original/07_local_vote_share.csv`](original/07_local_vote_share.csv) | 7th local elections (2018): vote share of each candidate's party in the 17 metropolitan mayor and governor races | [`tidy_election_data.R`](tidy_election_data.R) |
| [`original/08_local_vote_share.csv`](original/08_local_vote_share.csv) | 8th local elections (2022): the same | `tidy_election_data.R` |
| [`original/20th_presidential_vote_share.csv`](original/20th_presidential_vote_share.csv) | 20th presidential election (2022): vote share of the three main candidates by province | `tidy_election_data.R` |
| [`original/07_local_other_vote_share.csv`](original/07_local_other_vote_share.csv) | 2018: party shares of the municipal heads and the provincial and municipal councillors elected; shares of seats, despite the file name | `tidy_election_data.R` |
| [`original/08_local_other_vote_share.csv`](original/08_local_other_vote_share.csv) | 2022: the same | `tidy_election_data.R` |
| [`original/08_local_male_age_vote_share.csv`](original/08_local_male_age_vote_share.csv) | 2022 exit poll, men: DPK and PPP vote share and turnout by age group | `tidy_election_data.R` |
| [`original/08_local_female_age_vote_share.csv`](original/08_local_female_age_vote_share.csv) | 2022 exit poll, women: the same | `tidy_election_data.R` |

The script writes `vote_share.csv`, `exit_poll_2022.csv` and
`elected_officials_share.csv` to [`data/`](../data). Run it from the
repository root: `Rscript data-raw/tidy_election_data.R`.

## Where they came from

The CSVs were compiled by the project author in 2022: the election
results from the National Election Commission's statistics portal
([info.nec.go.kr](http://info.nec.go.kr)), and the exit-poll figures, which
the project attributes to the joint exit poll of the three terrestrial
broadcasters. The files themselves name no sources, and the values have not
been re-checked against them. They were first committed on 8 November 2022,
as CP949 files with Korean names (commit `056dfc9`). These are the UTF-8
copies made in 2026. They match the 2022 files exactly, except that 13 empty
trailing rows were dropped from the 2022 governor file.
[`data/README.md`](../data/README.md#provenance) has more detail, and the
problems found in the data.

## Keep them as they are

Don't edit these files. Corrections belong in the script, where they can be
reviewed, and known problems are documented in the
[caveats](../data/README.md#caveats). [`MD5SUMS`](MD5SUMS) records the
checksum of every file here. To confirm that none has changed, run
`md5sum -c data-raw/MD5SUMS` from the repository root.
