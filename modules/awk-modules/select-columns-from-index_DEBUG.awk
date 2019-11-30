######
#
# DEBUG code to check if the loop is actually storing what we think it is. 
#
#####
#Begin is performed before reading from stdin
BEGIN {
    FS = "\t"
    OFS = "\t"
    split(mapcols,mapout,"|")
    split(newcols,newout,",")

}
NR==1 {
    for (i=1; i<=NF; i++){
        # add "var" to hash key to be sure it is not mixed up with an internal
        # variable
        cix["var"$i] = i
        #printf "%s%s", $cix[i], OFS;
        printf "%s%s", $cix["var"$(i)], OFS;
        printf "%s%s", cix["var"$(i)], OFS;

    }
    print ""
    #print new header same order as provided
    for(k=1; k <= length(newout); k++){
        printf "%s%s", newout[k], OFS
    }
    print ""


}

NR>1 {
    for(j=1; j <= length(newout); j++){
        #extract index for the corresponding column/columns in the old file
        inx=sprintf("%s%s", "var", mapout[j])
        #printf "%s%s", inx, OFS;
        printf "%s%s", cix[inx], OFS;

    }
    print ""
}

#END { for (keyy in cix) { print keyy ": " $cix[keyy] } }


