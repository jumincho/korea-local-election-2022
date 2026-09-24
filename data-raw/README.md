# Raw inputs

The original files that the tidy data in [`data/`](../data) is built from,
kept byte for byte as they were committed, and the scripts that build it.
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
| [`shapefile/`](shapefile): `ctp_rvn.shp`, `.shx`, `.dbf`, `.prj` | Boundaries of the 17 provinces: 13 MB, 810,000 vertices, attributes encoded in CP949 | [`build_province_geometry.R`](build_province_geometry.R) |

`make data` runs both scripts. They write `vote_share.csv`,
`exit_poll_2022.csv`, `elected_officials_share.csv` and
`geo/provinces.geojson` to [`data/`](../data), and
[`tests/testthat/test-raw-equivalence.R`](../tests/testthat/test-raw-equivalence.R)
checks that every value in the tidy tables equals the corresponding cell here.

## Where they came from

- **The CSVs** were compiled by the project author in 2022: the election
  results from the National Election Commission's statistics portal
  ([info.nec.go.kr](http://info.nec.go.kr)), and the exit-poll figures, which
  the project attributes to the joint exit poll of the three terrestrial
  broadcasters. The files themselves name no sources, and the values have not
  been re-checked against them. They were first committed on 8 November 2022,
  as CP949 files with Korean names (commit `056dfc9`). These are UTF-8 copies
  that match them exactly, except that 13 empty trailing rows were dropped
  from the 2022 governor file.
- **The shapefile** was committed on 8 November 2022 (commit `4f79365`) and
  has not changed since. Where it came from was not recorded. Its name,
  attributes and projection match the province layer of the Ministry of the
  Interior and Safety's road-name address map, as redistributed by GIS
  Developer. It has also been credited to the National Spatial Data
  Infrastructure Portal. Neither source could be confirmed.

[`data/README.md`](../data/README.md#provenance) has more detail, and the
problems found in the data.

## Keep them as they are

Don't edit these files. Corrections belong in the scripts, where they can be
reviewed, and known problems are documented in the
[caveats](../data/README.md#caveats). [`MD5SUMS`](MD5SUMS) records the
checksum of every file here. To confirm that none has changed, run
`md5sum -c data-raw/MD5SUMS` from the repository root; `make test` checks too.
