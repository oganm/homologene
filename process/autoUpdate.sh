#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$parent_path"
cd ..
Rscript 'process/prepHomologene.R'
Rscript 'process/prepHomologene2.R'
