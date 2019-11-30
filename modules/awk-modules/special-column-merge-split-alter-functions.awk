#!/usr/bin/awk -f 

################################################################################
# Postional marker transformations 
################################################################################

function funx_CHR_BP_2_BP(markername) {
  split(markername,sp,":")
  BP = sp[2]
  return BP;
}

function funx_CHR_BP_2_CHR(markername) {
  split(markername,sp,":")
  CHR = sp[1]
  return CHR;
}
function funx_chrCHR_BP_2_CHR(markername) {
  split(markername,sp,":")
  CHR = sub("chr","",sp[1])
  return CHR;
}
function funx_chrCHR_2_CHR(chrCHR) {
  CHR = sub("chr","",chrCHR)
  return CHR;
}

################################################################################
# Allele annotation transformations 
################################################################################

function funx_lowCase_2_upperCase(allele) {
  upper=toupper(allele)
  return upper;
}

################################################################################
# Z-score calculations 
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

function funx_OR_and_Pvalue_2_Z(ORPvalue) {
  split(ORPvalue,sp,",")
  p2 = sp[2]/2
  s = sgn(log(sp[1]))*NormalCDFInverse(p2);
  return s;
}
function funx_logOR_and_Pvalue_2_Z(logORPvalue) {
  split(logORPvalue,sp,",")
  p2 = sp[2]/2
  s = sgn(sp[1])*NormalCDFInverse(p2);
  return s;
}
#echo "0.90,0.7" | awk -i special-column-merge-split-alter-functions.awk '{print funx_OR_and_Pvalue_2_Z($1)}'
