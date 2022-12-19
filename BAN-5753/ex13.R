# Install packages

#install.packages ('haven')
#install.packages('dplyr')
#install.packages ("My.stepwise")
#install.packages('rpart')
#install.packages('el071')
#install.packages('randomForest')
#install.packages('caret')
#install.packages('gbm')

# Call libraries
  
library (haven)
library (dplyr)
library (My.stepwise)
library (rpart)
library (e1071)
library (randomForest)
library (caret)
library (gbm)

# Read data
library("readxl")
setwd("/Users/mmarin/Documents/")
df <- read_excel("/Users/mmarin/Documents/ENROLLMENT_DATA.xlsx")

# drop columns indicated and columns that have constant values
df <- df %>% select(-one_of('ID','IRSCHOOL','Total','AllocProportion','LEVEL_YEAR','CONTACT_CODE1',
                            'SampleSize','Contact_Year','ActualProportion','SelectionProb','SamplingWeight'))

# Perform Summary Statistics
head(df,5) 
names(df) 
dim(df) 
str(df) 
summary(df) 
sum(is.na(df)) 


# Convert data into factors (categorical data)
df$Contact_Month <- factor (df$Contact_Month)
df$ETHNICITY <- factor (df$ETHNICITY)
df$Target_Enroll <-factor(df$Target_Enroll)


# Impute Null Values for Continous variables
# Return the column names containing missing observations
list_na <- colnames(df)[ apply(df, 2, anyNA) ]
print (list_na)

# Impute Missing data with the Mean
df$avg_income[is.na(df$avg_income)]<-mean(df$avg_income,na.rm=TRUE)
df$avg_income
sum(is.na(df$avg_income)) #Check number of null values in the dataset

df$distance[is.na(df$distance)]<-mean(df$distance,na.rm=TRUE)
df$distance
sum(is.na(df$distance)) #Check number of null values in the dataset

df$satscore[is.na(df$satscore)]<-mean(df$satscore,na.rm=TRUE)
df$satscore
sum(is.na(df$satscore)) #Check number of null values in the dataset

df$telecq[is.na(df$telecq)]<-mean(df$telecq,na.rm=TRUE)
df$telecq
sum(is.na(df$telecq)) #Check number of null values in the dataset

# Impute categorical data with mode
val <- unique(df$ETHNICITY[!is.na(df$ETHNICITY)])              # Values in ETHNICITY
my_mode <- val[which.max(tabulate(match(df$ETHNICITY, val)))]  # Mode of ETHNICITY
df$ETHNICITY[is.na(df$ETHNICITY)] <- my_mode  

val <- unique(df$sex[!is.na(df$sex)])                          # Values in sex
my_mode <- val[which.max(tabulate(match(df$sex, val)))]        # Mode of sex
df$sex[is.na(df$sex)] <- my_mode  


# create new data frame with the imputed rows
df_imp<-df

# 70/30 data split
 smp_size <- floor(0.75 * nrow(df_imp))
 smp_size
 
# set the seed to make your partition reproducible
 set.seed(123)
 train_ind <- sample(seq_len(nrow(df_imp)), size = smp_size)
 
 train <- df_imp[train_ind, ]
 test <- df_imp[-train_ind, ]
 
# check number of rows and na values
 nrow(train)
 nrow(test)
 nrow(df_imp)
 sum(is.na(df_imp))
 
# define logistic accuracy rate function
Logistic_accuracy_rate <- function(model, data) {
  target = c(data$Target_Enroll)
  glm.probs <- predict (model,newdata = data, type="response")
  pred_target <- ifelse(glm.probs>=0.5,1,0)
  df_class <- cbind(target,pred_target)
  class_tbl <- xtabs(~target + pred_target, data=df_class)
  class_pct <- class_tbl/length(target)
  classification_rate <- (class_pct[1,1]+class_pct[2,2])*100
  print(classification_rate) #Accuracy of the model
}
  
# Model 1 - Logistic Regression (No Variable Selection)
# Perform Logistic Regression
  Logistic_model1 <- glm(Target_Enroll~., family=binomial(link='logit'),data = train)
  summary (Logistic_model1)
  
# Accuracy For Logistic Regression
  
  Logistic_accuracy_rate(Logistic_model1,train)
  Logistic_accuracy_rate(Logistic_model1,test)

# Model 2 - Logistic Regression (Stepwise Variable Selection)
# Variable Selection using Stepwise (P Value)
  
variable_list <- c('avg_income','CAMPUS_VISIT','Contact_Date','Contact_Month','distance',
                     'ETHNICITY','hscrat','init_span','Instate','int1rat','int2rat','interest','mailq',
                     'premiere','REFERRAL_CNTCTS','satscore', 'SELF_INIT_CNTCTS','sex','SOLICITED_CNTCTS',
                     'telecq','TERRITORY','TOTAL_CONTACTS','TRAVEL_INIT_CNTCTS'     )
  
Logistic_model_Variable_Selection = My.stepwise.glm(Y="Target_Enroll",
                                                      variable.list =variable_list,
                                                      in.variable = "NULL",
                                                      data = train,
                                                      sle = 1,
                                                      sls = 0.5,
                                                      myfamily="binomial")

  
# Run a second logistic Regression based on the variables selected in the
# last iterations in the output
train_2 = subset(train,select = c(Target_Enroll, satscore,
                                    CAMPUS_VISIT,
                                    avg_income,
                                    Instate,sex,interest) )
    
Logistic_model2 <- glm(Target_Enroll~., family=binomial(link='logit'),data = train_2)
summary (Logistic_model2)

# Accuracy For Logistic Regression
                   
 Logistic_accuracy_rate(Logistic_model2,train)
 Logistic_accuracy_rate(Logistic_model2,test)
                   
# Create a function to return accuracy rate for the test data
 decision_accuracy_rate <- function(model, data) {
  target = c(data$Target_Enroll)
  glm.probs <- predict (model,data, type="class")
  pred_target <- glm.probs
  df_class <- cbind(target,pred_target)
  class_tbl <- xtabs(~target + pred_target, data=df_class)
  class_pct <- class_tbl/length(target)
  classification_rate <- (class_pct[1,1]+class_pct[2,2])*100
  print(classification_rate) #Accuracy of the model
}
                     
# Model 3 - Decision Tree
# grow tree
 Decision_Tree_Model <- rpart(Target_Enroll ~ .,
                              data = train,
                              method = 'class',
                              parms = list(split = "information") )
                     
decision_accuracy_rate(Decision_Tree_Model,train)
decision_accuracy_rate(Decision_Tree_Model,test)
                     
printcp (Decision_Tree_Model) # display the results
plotcp(Decision_Tree_Model) # visualize cross-validation results
summary(Decision_Tree_Model) # detailed summary of splits
                     
# plot tree
plot (Decision_Tree_Model,
      uniform=TRUE,
     main="Classification Tree for Target_Enroll")
                     
text (Decision_Tree_Model,
       use.n=TRUE,
       all=TRUE,
       cex=.8)
                     
# create attractive postscript plot of tree
post (Decision_Tree_Model,
         file = "Decision Tree Model.ps",
     title = "Classification Tree for Target_Enroll")
                     

#Model-4 (SVM)
#Create a function to return accuracy rate for the data
svm_accuracy_rate <- function(model,data) {
  target = c(data$Target_Enroll)
  x <- subset (data, select=-c(Target_Enroll) )
  glm.probs <- predict (model, x)
  pred_target <- glm.probs
  df_class <- cbind(target,pred_target)
  class_tbl<-xtabs(~target + pred_target, data=df_class)
  class_pct <- class_tbl/length(target)
  classification_rate <- (class_pct[1,1]+class_pct[2,2])*100
  print(classification_rate) #Accuracy of the model
}

# Use data selected in stepwsise regression
train_2
test_2 = subset(test,select = c(Target_Enroll, satscore,
                                  CAMPUS_VISIT,
                                  avg_income,
                                  Instate,sex,interest) )
#SVM MODEL 1 using Linear Kernel
svm_model1 <- svm(Target_Enroll ~ . ,
data=train_2,
kernel="linear")
print (svm_model1)
summary (svm_model1)
svm_accuracy_rate(svm_model1, train_2)
svm_accuracy_rate(svm_model1, test_2)

#SVM MODEL 2 using Polynomial Kernel
svm_model2 <- svm(Target_Enroll ~ . ,
data=train_2,
kernel="polynomial")
print (svm_model2)
summary (svm_model2)
svm_accuracy_rate(svm_model2, train_2)
svm_accuracy_rate(svm_model2, test_2)

#SVM MODEL 3 using radial basis Kernel
svm_model3 <- svm(Target_Enroll ~ . ,
data=train_2,
kernel="radial")
print (svm_model3)
summary (svm_model3)
svm_accuracy_rate(svm_model3, train_2)
svm_accuracy_rate(svm_model3, test_2)

#SVM MODEL 4 using sigmoid basis Kernel
svm_model4 <- svm(Target_Enroll ~ . ,
data=train_2,
kernel="sigmoid")
print (svm_model4)
summary (svm_model4)
svm_accuracy_rate(svm_model4, train_2)
svm_accuracy_rate(svm_model4, test_2)

#Model-5 (Random Forest)
# Define the control
trControl <- trainControl (method="cv",
                           number = 10,
                           search="grid")

Random_Forest_Model <- train(Target_Enroll ~ .,
                             data=train,
                             method = "rf",
                             metric = "Accuracy",
                             trControl = trControl)
                     
# Print the results
print (Random_Forest_Model)
                     
prediction <- predict (Random_Forest_Model, test)
confusionMatrix (prediction, test$Target_Enroll)
                     
# Model - 6 (Gradient Boosting)
# Define the control
trControl <- trainControl (method = "cv",
                           number = 10,
                           search = "grid")
set.seed (1234)

# Run the model
Gradient_Boosting_Model <- train(Target_Enroll ~ .,
                                 data = train,
                                 method = "gbm",
                                 metric = "Accuracy",
                                trControl = trControl)
# Print the results
print (Gradient_Boosting_Model)
prediction <- predict (Gradient_Boosting_Model, test)
confusionMatrix (prediction, test$Target_Enroll)
                     