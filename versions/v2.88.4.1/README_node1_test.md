# metage_v2.88.4.1 release snapshot

This directory preserves the scripts and WDL files used by the node1
`metage_v2.88.4.1` release.

## Contents

- `workflow/metage_v2.88.4.1.wdl`: standard workflow.
- `workflow/metage_v2.88.4.1_dehost.wdl`: dehost-enabled workflow.
- `scripts/`: complete runtime script snapshot. The script files are
  byte-identical to the archived v2.88.4 scripts; v2.88.4.1 changes are in
  the WDL layer.
- `VERSION`: release and container-image metadata.

Test inputs, FASTQ files, databases, Cromwell execution results and generated
result archives are intentionally excluded.

## Changes from v2.88.4

- Rename the workflows and container tag to v2.88.4.1.
- Make `parent_workflow_dir` accept a parent workflow UUID directly.
- Resolve parent workflows from the v2.88.4.1 and v2.88.4 standard/dehost
  Cromwell execution roots for incremental reuse.
- Apply the same parent-resolution behavior to Kraken2 result merging.

The workflow image is
`dockerhub.genostack.com/sanshu/metage:v2.88.4.1`. The two binning tasks keep
their separate MetaWRAP image as defined in the WDL files.
