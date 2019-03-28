# homologene 1.4.68.19.3.24 (since 1.1.68)

* Added a `NEWS.md` file to track changes to the package.
* Added `autoTranslate` function to allow automated translation of gene symbols or ids.
* `homologeneData2` is added as an updated version of the original homologene database (original database is not updated since 2014). This database includes the latest gene symbols and identifiers for every gene included in the original database. Outside CRAN (github version), this database is updated weekly. 
* Version number is extended to include the last update date of homologeneData2.
* `updateHomologene` function is added to allow users create their own updated
versions of homologene. Using `homologeneData2` as a baseline with this function
allows faster updates.
* `getGeneHistory`, `updateIDs` and `getGeneInfo` functions are added to allow users to update arbitrary gene lists with latest symbols and identifiers.
* All species originally repsented in the homologene database are added to the package.