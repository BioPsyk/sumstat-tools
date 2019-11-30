#!/usr/bin/awk -f 
{
  n = split($0, t, ",")
  for (i = 0; ++i <= n;){
    print t[i]
  }
}
