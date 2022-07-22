#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$parent_path"
cd ..
Rscript 'process/prepHomologene.R' > process/prepLog 2>process/prepLogErr
Rscript 'process/prepHomologene2.R' > process/prepLog2 2>process/prepLog2Err
