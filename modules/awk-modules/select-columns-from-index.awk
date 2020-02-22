#!/usr/bin/awk -f 

#DEBUG
#1)  In case more columns have been selected than have been declared
#    it could very well be because one colname does not exist, and
#    therefore sending back the $0 variable, which prints all fields

# trimming from: https://gist.github.com/andrewrcollins/1592991
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

# Begin is performed before reading from stdin
BEGIN {

    # important to use multiple occurences of whitespace and tab as field sep
    #FS = "[ \t]+"
    #bad idea to allow other things than tab separated entries
    FS = "\t"
    #Specify out field separator
    OFS = "\t"
    # split the input variable columns and store as out
    split(mapcols,mapout,"|")
    split(newcols,newout,",")
}
# visit only first line first
NR==1 {
    # loop thorugh all field for the first row and store in hash with its index
    for (i=1; i<=NF; i++){
        # add "var" to hash key to be sure it is not mixed up with an internal
        # variable
        tr=trim($i)
        cix["var"tr] = i
    }
    #print new header same order as provided
    for(k=1; k <= length(newout); k++){
        printf "%s%s", newout[k], OFS
    }
    print ""
}
# Then visit all other lines 
NR>1 {
    for(j=1; j <= length(newout); j++){
        #extract index for the corresponding column/columns in the old file
        inx=sprintf("%s%s", "var", mapout[j])
        #check if funx is there, which needs special treatment
        spec=index(inx, "funx")
        if(spec!=0){
          ett=index(inx, "(");
          tvo=length(inx);
          vars=substr(inx, ett + 1, tvo - ett - 1);
	  #put arguments in special function in hash
          split(vars,vars2,",")
          forEval=""
          inx2=sprintf("%s%s", "var", vars2[1])
          #forEval=sprintf("%s%s", forEval, $cix[inx2])
          forEval=sprintf("%s%s", forEval, $cix[inx2])
          if(length(vars2) > 1){
            for(l=2; l <= length(vars2); l++){
              inx2=sprintf("%s%s", "var", vars2[l])
              forEval=sprintf("%s,%s", forEval, $cix[inx2])
            }
          }

	  #create full query 
          #ett=index(inx, "funx_");
          tvo=index(inx, "(");
          funcname=substr(inx, 4, tvo - 4);
          #query=sprintf("%s%s%s%s", funcname, "(", forEval,")")


          #printf "%s%s", eval(query), OFS;
          #printf "%s%s", eval("funx_Eff_Err_2_Z($4,$5)"), OFS;
          printf "%s%s", @funcname(forEval), OFS;

          #printf "%s%s", @funcname("0.3,0.1"), OFS;
          #printf "%s%s", @funcname(0.3,0.1), OFS;
          #printf "%s%s", funcname, OFS;
          #printf "%s%s", funx_Eff_Err_2_Z($4,$5), OFS;
          #printf "%s%s", query, OFS;
          #printf "%s%s", forEval, OFS;
          #printf "%s%s", cix[inx2], OFS;
          #inx2=sprintf("%s%s", "var", vars2[2])
          #printf "%s%s", cix[inx2], OFS;
          #printf "%s%s", vars2[1], OFS;
        }else
          #print line
          printf "%s%s", $cix[inx], OFS;
    }
    print ""
}

######
#
# DEBUG code to check if the loop is actually storing what we think it is. 
#
#####
#Begin is performed before reading from stdin
#BEGIN {
#    #important to use multiple occurences of whitespace and tab as field sep
#    FS = "[ \t]+"
#    split(cols,out,",")
#}
#NR==1 {
#    for (i=1; i<=NF; i++){
#        cix[$i] = i
#    }
#}
#END { for (key in cix) { print key ": " cix[key] } }

