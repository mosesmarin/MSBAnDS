#install.packages("moments")
# Samples and Sampling Distributions
#
rm(list=ls())
library("moments")
#
# First sample - X1 is sampl1
pop_mean = 10
pop_sd = 5
samp_size = 50
X1 <- c(rnorm(samp_size, pop_mean, pop_sd))
X1
#
print(paste("The sample mean is: ", round(mean(X1),4)))
print(paste("The sample standard deviation is: ", round(sd(X1),4)))
print(paste("The sample median is: ", round(median(X1),4)))
print(paste("The sample skewness is: ", round(skewness(X1),4)))
print(paste("The sample kurtosis is: ", round(kurtosis(X1),4)))
h <- hist(X1, main="Histogram of Weight Loss in a sample of size 50", 
           xlab="Weight Loss in pounds", 
           border="blue", 
           col="green",
           xlim=c(-5,30),
           las=1, 
           breaks=14)
#
# Second Sample - X2 is sampl2
X2 <- c(rnorm(samp_size, pop_mean, pop_sd))
#
print(paste("The sample mean is: ", round(mean(X2),4)))
print(paste("The sample standard deviation is: ", round(sd(X2),4)))
print(paste("The sample median is: ", round(median(X2),4)))
print(paste("The sample skewness is: ", round(skewness(X2),4)))
print(paste("The sample kurtosis is: ", round(kurtosis(X2),4)))
hist(X2, main="Histogram of Weight Loss in a sample of size 50", 
     xlab="Weight Loss in pounds", 
     border="blue", 
     col="green",
     xlim=c(-5,30),
     las=1, 
     breaks=14)
#
# Generating an empirical sampling distribution of sample mean - X-bar
# Define the x_bar vector
num_samp = 1000
samp_size = 50
x_bar <- vector("numeric", num_samp)
#
# Each x-bar is the mean of a random sample of size 50 drawn from a Normal(10, 5)
#
# We are generating 1000 X-bars (from 1000 samples) and storing them in the x-bar vector
#
for (i in 1:num_samp) {
  x_bar[i] = mean(rnorm(samp_size, pop_mean, pop_sd))
}
#
# Calculate the empirical mean and emoirical standard deviation (called standard error) of x-bar 
# from the empirical sampling distribution formed by 1000 samples
#
Exp_x_bar <- mean(x_bar)
stderr <- sd(x_bar)
print(paste("The Empirical Expected value of X-bar is: ", round(Exp_x_bar,4)))
print(paste("The Theoretical Expected value of X-bar is: ", pop_mean))
print(paste("The Empirical Standard Error or standard deviation of X-bar is: ", round(stderr,4)))
print(paste("The Theoretical Standard Error or standard deviation of X-bar is: ", round(pop_sd/sqrt(samp_size),4)))
hist(x_bar, 
     main=paste("Histogram of Sampling Distribution of X-bar from ",num_samp,
                " samples of size ", samp_size, ""),
     xlab="X-bar", 
     border="blue", 
     col="green",
     xlim=c(5, 15),
     las=1, 
     breaks=20)
#
# Theoretically, 80% of X-bars are below:
print(paste("Theoretically, 80% of X-bars are between: ", qnorm(0.1, pop_mean, pop_sd/sqrt(samp_size)), " and ", qnorm(0.9, pop_mean, pop_sd/sqrt(samp_size))))

# Empirically, 80% of X-bars are below:
print(paste("Empirically, 80% of X-bars are between: ", quantile(x_bar, probs = 0.1, na.rm=FALSE, names = TRUE, type=2)," and ",quantile(x_bar, probs = 0.9, na.rm=FALSE, names = TRUE, type=2) ))
# Theoretical probability of finding a sample mean (X-bar) greater than 12
print(paste("The Theoretical Probability of X-bar greater than 12 is: ", round(Exp_x_bar,4)))
#
library("moments")
# Testing the Central Limit Theorem
#
#
# Generating an empirical sampling distribution of sample mean - X-bar
# Define the x_bar vector
num_samp = 10000
samp_size = 1000
x_bar <- vector("numeric", num_samp)
#
# Each x-bar is the mean of a random sample of size 100 drawn from a 3 different distrbutions
# exponential (right-skewed), uniform (symmetric), beta (left-skewed)
# We are generating 1000 X-bars (from 1000 samples) and storing them in the x-bar vector
#
for (i in 1:num_samp) {
  # Uncomment the distribution to be used in the next three lines; leave the other two commented
  #   x_bar[i] = mean(rexp(samp_size, 1))
  #   x_bar[i] = mean(runif(samp_size, 0, 2))
  x_bar[i] = mean(rbeta(samp_size, 50, 1, ncp = 0))
}
#
# Calculate the mean and standard deviation (called standard error) of x-bar 
# from the empirical sampling distribution formed by 1000 samples of size 50
#
Expec_x_bar <- mean(x_bar)
stderr <- sd(x_bar)
print(paste("The Expected value of X-bar is: ", round(Expec_x_bar,4)))
print(paste("The standard error or standard deviation of X-bar is: ", round(stderr,4)))
hist(x_bar, 
     main=paste("Histogram of Sampling Distribution of X-bar from ",num_samp,
                " samples of size ", samp_size, ""),
     xlab="X-bar", 
     border="blue", 
     col="green",
     #     xlim=c(5, 15),
     las=1, 
     breaks=20)
# We also collect other quantities such as skewness and kurtosis of the sampling distribution
#
skewness(x_bar)
kurtosis(x_bar)
#
forbes_data <-c(58,51,61,56,59,74,63,53,50,59,60,60,57,46,55,63,57,47,55,57,43,61,62,49,67,67,55,55,49)
print(paste("The sample X-bar is :",round(mean(forbes_data),4)))
print(paste("The standard deviation of the sample is :",round(sd(forbes_data),4)))
#