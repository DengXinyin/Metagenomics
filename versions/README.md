# Metagenomics workflow snapshots

These directories preserve the WDL and script snapshots used for the node1
workflow releases. The older snapshots are reconstructed from the dated local
release bundles and file modification times because the working tree was
updated in place.

- `v2.88.2`: scripts at or before 2026-08-27; WDL from the v2.88.2 node1 bundle.
- `v2.88.3`: scripts at or before 2026-08-30; WDL from the v2.88.3 node1 bundle.
- `v2.88.4`: current scripts, including the `anno_cumulative`/incremental merge
  fixes and Kraken2 merge support; WDL from the v2.88.4 node1 bundle.
- `v2.88.4.1`: complete v2.88.4 script snapshot plus the v2.88.4.1 standard
  and dehost WDL files; adds parent-workflow UUID resolution across the
  v2.88.4/v2.88.4.1 standard and dehost Cromwell roots.
