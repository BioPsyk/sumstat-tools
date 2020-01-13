#!/usr/bin/awk -f 

function in_GTCA(field){
  ans=field ~ /^[GCTA]+$/;
  return ans;
}
function indl(f1,f2){
  ans=length(f1)!=1 || length(f2)!=1
  return ans;
}
function homozygous(one,two){
  ans=one==two;
  return ans;
}
function palindrom(one,two){
  ans=(one=="A" && two=="T") || (one=="T" && two=="A") || (one=="G" && two=="C") || (one=="C" && two=="G");
  return ans;
}
function opp(a){
  if(a=="A"){ans="T"}
  else if(a=="T"){ans="A"}
  else if(a=="G"){ans="C"}
  else{ans="G"}
  return ans;
}
function notExpectedA2(a1,a2,b1,b2,re,al){
  ans=(a1 == re) && (!a2 == al) || (b1 == re) && (!b2 == al)
  return ans;
}
function calcExpectedA2(a1,re,al){
  if(a1 == re){a2i=al}
  else if(a1 == al){a2i=re}
  else if(opp(a1) == re){a2i=opp(al)}
  else{a2i=opp(re)}
  return a2i;
}
function possiblePairs(a1,a2,b1,b2,re,al){
  ans=(re == a1 && al == a2) || (re == b1 && al == b2) || (re == a2 && al == a1) || (re == b2 && al == b1)
  return ans;
}
function effmod(a1,a2,re){
  if(a1==re || b1 == re){return 1}else{return -1}
}
