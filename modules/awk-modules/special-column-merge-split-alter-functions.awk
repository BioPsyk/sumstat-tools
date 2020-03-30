#!/usr/bin/awk -f 

################################################################################
# Postional marker transformations 
################################################################################
function funx_default(markername) {
  return toupper(markername);
}
function funx_chrCHR_2_CHR(markername) {
  mn2 = gsub(/[c|C][h|H][r|R]/,"",markername)
  return mn2;
}

#chr:bp
function funx_CHR_BP_2_CHR(markername) {
  split(markername,sp,"[:_]")
  CHR = sp[1]
  return CHR;
}
function funx_CHR_BP_2_BP(markername) {
  split(markername,sp,"[:_]")
  BP = sp[2]
  return BP;
}
#chrchr:bp
function funx_chrCHR_BP_2_CHR(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  return sp[1];
}
function funx_chrCHR_BP_2_BP(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  return sp[2];
}



#chr:bp:A1
function funx_CHR_BP_EA_2_CHR(markername) {
  split(markername,sp,"[:_]")
  CHR = sp[1]
  return CHR;
}
function funx_CHR_BP_EA_2_BP(markername) {
  split(markername,sp,"[:_]")
  BP = sp[2]
  return BP;
}
function funx_CHR_BP_EA_2_EA(markername) {
  split(markername,sp,"[:_]")
  EA = toupper(sp[3])
  return EA;
}

#chrchr:bp:A1
function funx_chrCHR_BP_EA_2_CHR(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  CHR = sp[1]
  return CHR;
}
function funx_chrCHR_BP_EA_2_BP(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  BP = sp[2]
  return BP;
}
function funx_chrCHR_BP_EA_2_EA(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  EA = toupper(sp[3])
  return EA;
}


#chr:bp:A1:A2
function funx_CHR_BP_EA_AA_2_CHR(markername) {
  split(markername,sp,"[:_]")
  CHR = sp[1]
  return CHR;
}
function funx_CHR_BP_EA_AA_2_BP(markername) {
  split(markername,sp,"[:_]")
  BP = sp[2]
  return BP;
}
function funx_CHR_BP_EA_AA_2_EA(markername) {
  split(markername,sp,"[:_]")
  EA = toupper(sp[3])
  return EA;
}
function funx_CHR_BP_EA_AA_2_AA(markername) {
  split(markername,sp,"[:_]")
  AA = toupper(sp[4])
  return AA;
}

function funx_chrCHR_BP_EA_AA_2_CHR(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  CHR = sp[1]
  return CHR;
}
function funx_chrCHR_BP_EA_AA_2_BP(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  BP = sp[2]
  return BP;
}
function funx_chrCHR_BP_EA_AA_2_EA(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  EA = toupper(sp[3])
  return EA;
}
function funx_chrCHR_BP_EA_AA_2_AA(markername) {
  gsub(/[c|C][h|H][r|R]/,"",markername)
  split(markername,sp,"[:_]")
  AA = toupper(sp[4])
  return AA;
}

#
# underline versions
#
##chr_bp
#function funx_underline_CHR_BP_2_CHR(markername) {
#  split(markername,sp,"_")
#  CHR = sp[1]
#  return CHR;
#}
#function funx_underline_CHR_BP_2_BP(markername) {
#  split(markername,sp,"_")
#  BP = sp[2]
#  return BP;
#}
##chrchr_bp
#function funx_underline_chrCHR_BP_2_CHR(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  return sp[1];
#}
#function funx_underline_chrCHR_BP_2_BP(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  return sp[2];
#}
#
##chr_bp_A1
#function funx_underline_CHR_BP_EA_2_CHR(markername) {
#  split(markername,sp,"_")
#  CHR = sp[1]
#  return CHR;
#}
#function funx_underline_CHR_BP_EA_2_BP(markername) {
#  split(markername,sp,"_")
#  BP = sp[2]
#  return BP;
#}
#function funx_underline_CHR_BP_EA_2_EA(markername) {
#  split(markername,sp,"_")
#  EA = sp[3]
#  return EA;
#}
#
##chrchr_bp_A1
#function funx_underline_chrCHR_BP_EA_2_CHR(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  CHR = sp[1]
#  return CHR;
#}
#function funx_underline_chrCHR_BP_EA_2_BP(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  BP = sp[2]
#  return BP;
#}
#function funx_underline_chrCHR_BP_EA_2_EA(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  EA = sp[3]
#  return EA;
#}
#
#
##chr_bp_A1_A2
#function funx_underline_CHR_BP_EA_AA_2_CHR(markername) {
#  split(markername,sp,"_")
#  CHR = sp[1]
#  return CHR;
#}
#function funx_underline_CHR_BP_EA_AA_2_BP(markername) {
#  split(markername,sp,"_")
#  BP = sp[2]
#  return BP;
#}
#function funx_underline_CHR_BP_EA_AA_2_EA(markername) {
#  split(markername,sp,"_")
#  EA = sp[3]
#  return EA;
#}
#function funx_underline_CHR_BP_EA_AA_2_AA(markername) {
#  split(markername,sp,"_")
#  AA = sp[4]
#  return AA;
#}
#
#function funx_underline_chrCHR_BP_EA_AA_2_CHR(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  CHR = sp[1]
#  return CHR;
#}
#function funx_underline_chrCHR_BP_EA_AA_2_BP(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  BP = sp[2]
#  return BP;
#}
#function funx_underline_chrCHR_BP_EA_AA_2_EA(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  EA = sp[3]
#  return EA;
#}
#function funx_underline_chrCHR_BP_EA_AA_2_AA(markername) {
#  gsub(/[c|C][h|H][r|R]/,"",markername)
#  split(markername,sp,"_")
#  AA = sp[4]
#  return AA;
#}
#

################################################################################
# Allele annotation transformations 
################################################################################

function funx_lowCase_2_upperCase(allele) {
  upper=toupper(allele)
  return upper;
}

################################################################################
# Z-score calculations 
# Note from Andrew:   We need meta-data to confirm logistic or linear regression
#                     LMM and gLMM may not work in the same ways, esp. for downstream analyses
#
#
#
################################################################################


#The z-value is the regression coefficient divided by its standard error.
function funx_Eff_Err_2_Z(efferr) {
  split(efferr,sp,",")
  s = sp[1]/sp[2];
  return s;
}


#log(x) in awk is natural log
#To calc negative log10: awk -F"," '{a = -log($16)/log(10); printf("%0.4f\n", a)}'

#z = ln(OR)*OR/se  , https://www.stata.com/statalist/archive/2003-02/msg00740.html
# Note from Andrew:  I don't understand this formula for z, I think it is not the general formula for data we work with.
#                    s.e. of an OR is not that meaningful because its not a normally distributed stat, so 95% confidence,
#                    which is asymetric ( i.e., it may be ~1 with a 95% CI = 0.9 to 1.3 ) is prefferred and usually reported.
#                    This is because the same info is contained in an OR from 0 to 1 and from 1 to infinity, the 
#                    "opposite" effect isnt simply negative of the effect.  
#                    I think for most case-control studies we can assume a logistic regression where the s.e. is nearly always
#                    on the ln(OR) scale, although we can investigate how that relates to chi-square, trend tests, etc.
#                    Perhaps we can build in a fail safe, like is the s.e. consistent with Beta/s.e.=Z if all of the stats
#                    are present?
#                    This might be a better cite, although it's just a quick google result:
#                    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1065119/
#
#                    I now see the code below is consistent with what i just wrote ... ¯\_(ツ)_/¯

function funx_OR_logORErr_2_Z(ORerr) {
  split(ORerr,sp,",")
  s = log(sp[1])/sp[2];
  return s;
}

function funx_logOR_logORErr_2_Z(logORlogErr) {
  split(logORlogErr,sp,",")
  s = sp[1]/sp[2];
  return s;
}

# We have to make our own awk function for the normal inverse cumulative distribution function
# C code version available here: https://www.johndcook.com/blog/normal_cdf_inverse/
# and a brief explanation of the concept
# https://stats.stackexchange.com/questions/265925/what-is-inverse-cdf-normal-distribution-formula
function RationalApproximation(t) {
   # Abramowitz and Stegun formula 26.2.23.
   # The absolute value of the error should be less than 4.5 e-4.

   # Note from Andrew: This could be worth studying relative to R or some other tool. 
   #                    that tolerance is fine for a normal z-score, but in the range of GWAS significance (p < 1e-10),
   #                    does it matter?  A quick test suggest no, but something to keep in mind, maybe?
   #                    R uses this algorithm:
   #                    http://csg.sph.umich.edu/abecasis/gas_power_calculator/algorithm-as-241-the-percentage-points-of-the-normal-distribution.pdf
   #                    I am not sure how relevant any of this is, but if we start choosing approximations we might
   #                        want to consider a few options. 

   #store as arrays
   c[1]=2.515517
   c[2]=0.802853
   c[3]=0.010328
   d[1]=1.432788
   d[2]=0.189269
   d[3]=0.001308

   ret = t - ((c[2]*t + c[1])*t + c[0])/(((d[2]*t + d[1])*t + d[0])*t + 1.0)
   return ret;
}

function NormalCDFInverse(p)
{
    if (p <= 0.0 || p >= 1.0)
    {
      return NA
    }

    # See article above for explanation of this section.
    if (p < 0.5)
    {
        # F^-1(p) = - G^-1(p)
        return -RationalApproximation( sqrt(-2.0*log(p)) );
    }
    else
    {
        # F^-1(p) = G^-1(1-p)
        return RationalApproximation( sqrt(-2.0*log(1-p)) );
    }
}

function sgn(x){ 
  if (x>0)
  { 
    return 1
  }
  else if (x<0){
    return -1
  } 
  else 
  {
    return 0
  }
}

function abs(v) {return v < 0 ? -v : v}

## Notes from Andrew:
##  I think the below equations need two modifications:
##      A two-tailed adjustment (p-values in GWAS are typically two-tailed):    
##      - NormalCDFInverse(p2) -> NormalCDFInverse(p2/2)     [fixed 2020-01-21:Jesper]
##      A sign consistency adjustment (ensure that the result of NormalCDFInverse is positive):
##      - NormalCDFInverse(p2/2) -> abs( NormalCDFInverse(p2/2) )    [fixed 2020-01-21:Jesper]
##
##  Id like to test the following input:
##    OR = 0.5, P = 0.95, which should give Z = -0.0627
##    OR = 0.5, P = 0.05, which should give Z = -1.9599
##    OR = 1.5, P = 0.95, which should give Z = 0.0627
##    OR = 1.5, P = 0.05, which should give Z = 1.9599

function funx_OR_and_Pvalue_2_Z(ORPvalue) {
  split(ORPvalue,sp,",")
  p2 = sp[2]/2
  s = sgn(log(sp[1]))*abs(NormalCDFInverse(p2/2));
  return s;
}
function funx_logOR_and_Pvalue_2_Z(logORPvalue) {
  split(logORPvalue,sp,",")
  p2 = sp[2]/2
  s = sgn(sp[1])*abs(NormalCDFInverse(p2/2));
  return s;
}
#echo "0.90,0.7" | awk -i special-column-merge-split-alter-functions.awk '{print funx_OR_and_Pvalue_2_Z($1)}'

################################################################################
# SE calculations 
# Note from Andrew: It might be worth trying to recover the s.e. from the Z for completeness
#                   like if they only give OR, ln(OR) and z or P
#                   Some advanced methods use the s.e. from shrinkage or other tricks
#
#                   We might also consider testing the robustness of our transformations in real world analyses:
#                   We could take some complete stats and censor different columns, re-estimate the values,
#                   compute h2, PRS, etc.
#                   In some cases our computed might be better, they could correct errors by forcing internal
#                   consistency.  This could be a "perk" of our package.  More than just rearranging columns.
################################################################################

function funx_logOR_Z_2_se(logORZ) {
  split(logORlogErr,sp,",")
  s = sp[1]/sp[2];
  return s;
}

function funx_OR_Z_2_se(ORZ) {
  split(logORlogErr,sp,",")
  s = log(sp[1])/sp[2];
  return s;
}

################################################################################
# P-Value calculations 
# Note from Andrew:   I am not sure how to computes the Cumulative Normal Distribution (from x to p)
#                     The R code is: P <- 2*pnorm( -abs( Z ) )
#
################################################################################
