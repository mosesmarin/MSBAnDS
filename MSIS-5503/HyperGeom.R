# Hypergeometric Distribution
#
#dhyper(x, m, n, k, log = FALSE) where 
# x = number of successes in sample (k in our notes)
# m = number of successes in population (K in our notes)
# n = number of failures in population (N - K) in our notes
# k = sample size (n in our notes)
# probability of obtaining the x=4 Females ("successes"), m=60 of whom are Females, n=40 Males ("failures").
#
print(paste("probability of obtaining the x=4 Females, m=60 of whom are Females, n=40 Males ", 
            round(dhyper(4, 60, 40, 10, log = FALSE),4)))
#
#
#table of probabilities
nsize = 10
result <- vector("numeric", 11)
cum_result <- vector("numeric", 11)
xPx <- vector("numeric", 11)
x2Px <- vector("numeric", 11)
for (i in 0:nsize) {
  result[i+1] <- dhyper(i, 60, 40, 10, log = FALSE)
  xPx[i+1] <- i*result[i+1]
  x2Px[i+1] <- i*xPx[i+1]
  cum_result[i+1] <- phyper(i, 60, 40, 10, log = FALSE)
}
round(result[1:11], 4)
round(cum_result[1:11], 4)
#
# Mean = sum of xPx
Exp_val = sum(xPx)
print(paste("The Expected Value is",Exp_val, sep = " "))

# Var = sum of X2Px - (sum(xPx)^2)
varian = sum(x2Px) - Exp_val*Exp_val
print(paste("The Variance is",varian, sep = " "))
#
print(paste("probability of obtaining the x>=5 non-proficient ", 
            1 - round(phyper(4, 8, 20, 10, log = FALSE),4)))
#
print(paste("probability of obtaining the x<=3 non-proficient ", 
            round(phyper(3, 8, 20, 10, log = FALSE),4)))