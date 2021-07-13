#!/bin/bash

# This script takes the standard kraken output (NOT the report) and 
# provides the full lineage of the taxonomic assignment.
# Run kraken withOUT the --use-names option.

# You will need to download NCBI's EDirect software to run this script

# input: Kraken standard output
KRAKEN="$1"

# collect taxIDs to run through NCBI Taxonomy Browser
grep '^C' $KRAKEN | cut -f3 > taxids.txt

# get NCBI Taxonomy full lineage for each taxID
while read line; 
do
if [[ "$line" == '0' ]]; then 
echo $line ; continue  
fi 
efetch -db taxonomy -id $line -format xml | \
{ echo $line ; \
xtract -pattern Taxon -first TaxId -sep "_" -element Rank,ScientificName \
-element Taxon -block "*/Taxon" -unless Rank -equals "no rank" \
-tab "\t" -sep "_" -element Rank,ScientificName; } | \
tr '\n' '\t' ; 
echo -e "" ; 
done < taxids.txt > temp.full-taxonomy.txt

# create dictionary of taxID lineage with table-formatted lineage
awk -F$'\t' '{OFS=FS} 
{split($0, taxa, "\t"); 
for (rank in taxa) { 
split(taxa[rank],rankname,"_"); 
a[rankname[1]] = rankname[2] };
print taxa[1], taxa[2], a["superkingdom"], a["kingdom"], a["phylum"], a["class"], a["order"], a["family"], a["genus"], a["species"];
split("",a)
}' temp.full-taxonomy.txt > temp2.full-taxonomy.text

# join with original kraken output
awk 'BEGIN { FS="\t"; OFS="\t" } NR==FNR{ seen[$3]=$1FS$2FS$4; next } NF{ print seen[$1], $0 }' \
$KRAKEN temp2.full-taxonomy.text > temp3.full-taxonomy.text

# add headers
{ echo -e "status\tsequenceID\tlength\ttaxid-in\ttaxid-out\tsuperkingdom\tkingdom\tphylum\tclass\torder\tfamily\tgenus\tspecies"; \
cat temp3.full-taxonomy.text; } > full-lineage.kraken.txt

