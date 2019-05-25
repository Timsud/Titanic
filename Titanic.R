setwd('C:/Users/User/Documents/working on some projects/Kaggle projects/Titanic')
install.packages("mice")
install.packages('stringi')
install.packages('missMDA')
install.packages('MLmetrics')
install.packages('stringr')
install.packages('rpart')
install.packages('extraTrees')
install.packages('randomForest')
install.packages('GPfit')
install.packages('raster')
install.packages('adabag')
install.packages('gbm')
install.packages("xgboost")
install.packages("neuralnet")
library(mice)
library(gbm)
library(missMDA)
library(stringi)
library(stringr)
library(zoo)
library(shiny)
library(ggplot2)
library(xgboost)
library(tidyr)
library(MLmetrics)
library(rpart)
library(stats)
library(extraTrees)
library(e1071)
library(caret)
library(randomForest)
library('GPfit')
library(dplyr)
library(raster)
library(adabag)
library(neuralnet)
# Downloading of the Data.
train = read.csv('train.csv')
test = read.csv('test.csv')

# Now lets examine the data we have.  ##### EDA ####
str(train)
summary(train)
apply(apply(train, 2, is.na),2, sum) # In variable age we have 177 missing values, what really a lot is. And we have to find method to paste it.
# Here we write function to leave just numeric values in our dataframe. 
conv_to_num = function(x){
   puf = x
   del = 0
   j=0
   for(i in 1:ncol(x)){
       if(!(class(x[,i])%in% c('numeric','integer'))){
         j = j+1
         del[j] = i 
         
       }  
   }
   puf = x[,-del]
  
   return(puf)
} 
train_num = conv_to_num(train) # Just numeric values. Now we can work with function to input missing data.
imputed = mice(train_num, m=5, maxit = 50, method = 'pmm', seed = 500) # We used here for imputation  'Predictive mean matching'. Explanation:
#Predictive mean matching calculates the predicted value of target variable Y according to the specified imputation model. 
#For each missing entry, the method forms a small set of candidate donors (typically with 3, 5 or 10 members) from all complete cases
#that have predicted values closest to the predicted value for the missing entry.
#One donor is randomly drawn from the candidates, and the observed value of the donor is taken to replace the missing value. 
#The assumption is the distribution of the missing cell is the same as the observed data of the candidate donors.
summary(imputed)
mice::complete(imputed,2) # from 5 datasets that we have i will take 2nd.
# Now we have to put 'Age' variable in our Dataset.
train[,'Age'] = mice::complete(imputed, 2)[['Age']]
# Now we dont have any missing values.
head(train)
as.character(train$Cabin) # The most information about cabin is unfortunately lost. Therefore this variable wouldnt be so useful in our analysis. We will drop him.
train = train[,-11]
                                   ####################################
##### In this case we dont need that because we have imputed missed values in other way. But its a very good possibility 
##### to impute data based on their initials. 
# Now lets create new variable 'initial'.
# train[['initial']] = str_extract_all(as.character(train$Name), '[A-Z|a-z]+\\.')
                                   ####################################
#We see that we have some missing data in 'Embarked' variable.
train$Embarked
# The best possibility would be to check which class there is at most and input that type of data.
table(train$Embarked) # In this case its class 'S'.
# Thats our way how we add needed classes:
puf = as.character(train$Embarked)
puf[which(regexpr("[A-Z]", as.character(puf))<0)] = 'S'
train$Embarked = factor(puf, levels = c("C","Q","S"))
train$Embarked

str(train)

# Now we want to find some relationships between them with the help of grpahs.
# We want to do it with the help of shiny.
train_sh = cbind(train, rep(NA, nrow(train)))
ui <- (pageWithSidebar(
  headerPanel("Select Options"),   
  sidebarPanel(
       
       selectInput('variable1', 'Variable x:',selected = NULL, c( "PassengerId", "Survived", "Pclass", "Name" , "Sex","Age","SibSp" , "Parch", "Ticket","Fare","Embarked" )),
       checkboxInput('var_y', 'Variable y:', TRUE),
       selectInput('variable2', 'Variable y:' ,selected = NULL, c( "PassengerId", "Survived", "Pclass", "Name" , "Sex","Age","SibSp" , "Parch", "Ticket","Fare", "Embarked" )),
       checkboxInput('var_g', 'Group:', TRUE),
       selectInput('group', 'Group by:',selected = NULL, c("PassengerId", "Survived", "Pclass", "Name" , "Sex","Age","SibSp" , "Parch", "Ticket", "Fare", "Embarked" )),
       selectInput("plot_type","Type of the plot:",
                   list(scatterplot = 'scatterplot', boxplot = "boxplot", histogram = "histogram", density = "density", barplot = "barplot")
       )
     ),
  mainPanel(
       h3(textOutput('plot_type')),
       uiOutput("plot")
       )
))

server = function(input, output, session){
  
 
  
  
  output$plot_type <- renderText({
    switch(input$plot_type,
           "scatterplot" = "Scatterplot",
           "boxplot" 	= 	"Boxplot",
           "histogram" =	"Histogram",
           "density" 	=	"Density plot",
           "barplot" 		=	"Bar plot")
  })
  
  output$plot <- renderUI({
    plotOutput("p")
  })
  
  output$p = renderPlot({
    
    plot_type<-switch(input$plot_type,
                      "scatterplot" = geom_point(),
                      "boxplot" 	= geom_boxplot(),
                      "histogram" =	geom_histogram(alpha=0.5,position=position_dodge(), stat = 'count'),
                      "density" 	=	geom_density(alpha=.75),
                      "barplot" 		=	geom_bar(position=position_dodge(),stat= 'identity')
    )
    
    
    if(input$plot_type%in% c( "histogram","density")){
         if(input$var_g == TRUE){
              p<-ggplot(data = train, aes_string(
                         x 		= input$variable1,
                         fill 	= input$group
                         )) + plot_type
       }  else{
              p<-ggplot(data = train, aes_string(
                         x 		= input$variable1
                       )) + plot_type
       } 
            
          
      
 }  else {
        if(input$var_y == TRUE && input$var_g == TRUE){
             p<-ggplot(data = train, aes_string(
                  x 		= input$variable1,
                  y 	= input$variable2, 
                  fill =  input$group 
                 )) + plot_type
   }    else if(input$var_y == FALSE && input$var_g == TRUE){
             p<-ggplot(data = train, aes_string(
                  x 		= input$variable1,
                  fill=  input$group 
                 )) + plot_type
   }    else if(input$var_y == TRUE && input$var_g == FALSE){
             p<-ggplot(data = train, aes_string(
                 x 		= input$variable1,
                 y 	= input$variable2
                )) + plot_type
   }    else{
            p<-ggplot(data = train, aes_string(
                x 		= input$variable1
               )) + plot_type
   }
   
   
   
 }
   print(p)       
})
}



shinyApp(ui, server)

#### With this interactive app we can produce different graphs to analyze relationships between variables.

#### Now lets analyze different relationships with some ggplots and keep in mind that same plots we can do with our app:

### Analyzing 'Sex' variable.
ggplot(train, aes(x = Sex)) + geom_histogram(stat = 'count')  
# There were more males than Females on Titanic.

ggplot(train, aes(x = Sex,fill = Survived)) + geom_histogram(stat = 'count') 
# From this plot we can conclude that there are more females who survive this crash as males.And a bigger part 
# of males is dead.


ggplot(train, aes(x = Embarked,fill = Sex)) + geom_histogram(stat = 'count')  
# We see that the most pepople had Southampton as Port of their Embarkation.And the biggest part of these people are males.
# as in every port.


ggplot(train, aes(x = Sex, y = Age)) + geom_boxplot()
# From this boxplot we can conclude that males were in average older than females.


ggplot(train, aes(x = Pclass, fill = Sex)) + geom_histogram(stat = 'count')
# Here we see number of males and females in different classes. 3rd class is the biggest one and has the most passengers.



## We see that this variable will be very important for our model.

#### Pclass variable.

ggplot(train, aes(x = as.factor(Pclass), fill = as.factor(Survived))) + geom_histogram(stat = 'count', position=position_dodge())  
# From the plot we can conclude that the biggest number of deaths is in 3rd class.
# and the biggest number of survived passengers is in the first class.

 
srv_anz = train %>% group_by(Pclass,Sex) %>% filter(Survived == 1) %>% summarise(n=n())
srv_anz = spread(srv_anz, Sex, n)
not_srv_anz = train %>% group_by(Pclass,Sex) %>% summarise(n=n())
not_srv_anz =spread(not_srv_anz, Sex, n) 
srv_prz = data.frame(srv_anz[,1],srv_anz[,2:3]/not_srv_anz[,2:3]) # Here we found the percentage of survived 
# people in different classes based on their gender. We see that the worse the class the smaller percent of
# survived passengers. This percentage is decreasing for females and males.
# This variable will be very helpful in our model because it has some explanation power for 'Survived' variable.
  

### Age variable.
train$Pclass = factor(train$Pclass)
ggplot(train, aes(x = Pclass, y=Age,fill=Sex)) + geom_boxplot() # What we see here is that people in the first 
# class are older in average and its logical because tickets for this class are more expensive. Also males are 
# older in average in every class. And there are more males in every class.


ggplot(train, aes(x = Pclass, y=Age,fill=Survived)) + geom_boxplot() # In this graph we see that age of survived
# passengers on average smaller than of not survived. And the average age of survived passengers is different,
# because as we said before that the average age among three classes is different.

# Now we want to do the same plot but to see whether there is some difference based on gender.
ggplot(train, aes(x = Pclass, y=Age,fill=Survived)) + geom_boxplot()+facet_wrap(~Sex) # It repeats the same pattern
# as in the last graph except females in the first class, where the average age of survived passengers is higher.
# in other cases its smaller. Because as we know first passengers, who could leave Titanic, were Kids and women.
# For all males the probability of survival is less with the increasing age. 


ggplot(train, aes(x = Pclass, y=Age,fill=Survived)) + geom_violin() # with the help of violin plots we can see
# the approximate age of survived passangers. its 20-50 years in the first class, 10-50 in the second class, 0-45 in the third class.

ggplot(train, aes(x = Sex, y=Age,fill=Survived)) + geom_violin() # From this Violin plot we see again that 
# there are more survived females as males.There are less.


# Histogramm of Age for survived and not survived passengers.
ggplot(train, aes(x = Age)) + geom_histogram() + facet_wrap(~Survived) # We can conclude from this histogramm
# that there were a lot of kids, who were saved. And the most deaths are in the age group of 20-40 years.


### Embarked variable.
head(train)
# Here we want to see how much people was embarked from every Port:
ggplot(train, aes(x=Embarked)) + geom_histogram(stat= 'count') # Here we see that 
# for the most people Port of Embarkation was Southampton.

# Boxplot of Age in every Port of Embarkation:
ggplot(train, aes(x=Embarked, y = Age)) + geom_boxplot() # We see that Age on average
# was equal but 'Southampton' class there are more outliers, it means more older passengers
# what makes sense to me.

# Boxplot of Fare in every Port of Embarkation:
ggplot(train, aes(x=Embarked, y = Fare)) + geom_boxplot() # We see that people,
# who was embarked Cherbourg, paid on everage more. And in Southampton people paid on average 
# less but there are many outliers.

# Histogram of Embarked and Pclass. From that plot we can see: "How much people from 
# different classes were embarked in every Port?" 
ggplot(train, aes(x=Embarked,  fill = as.factor(Pclass))) + geom_histogram(stat='count')
# We see that the most part of 3rd class was embarked in Southampton. And now we can
# understand the last plot. Therefore we had there on average smaller Fare and so much
# outliers, because some part of 1st class was embarked in Southampton as well.

# Now lets see how much people survived in every group:
ggplot(train, aes(x=Embarked,  fill = as.factor(Survived))) + geom_histogram(stat='count', position=position_dodge())
# Plot says that the most people survived from Southampton port.Because from this port 
# the biggest part of passengers was embarked.

# Histogram of sexes in every Port:
ggplot(train, aes(x=Embarked,  fill = as.factor(Sex))) + geom_histogram(stat='count', position=position_dodge())
# the biggest part of passengers from Southampton was males as in other ports but not
# with such big difference as here.

                       ##### Data Cleaning #####
                           ### For train Data ###
# Now we want to clean our Data in the best way possible.

# First of all we begin with 'Name' variable. As we can think that name is not so important
# for our analysis but what real important is title of the person. We have seen that
# there is some dependence between survavial probability and Sex.
train$Title = str_extract(train$Name,' ([A-Za-z]+)[.]')
table(str_extract(train$Name,' ([A-Za-z]+)[.]')) # We see that some titles less than others
# therefore we can put titles, which occur not so often, in 'other' group.
bool = str_detect(train$Title, c('Capt|Col|Countess|Don|Dr|Jonkheer|Lady|Major|Mlle|Mme|Rev|Sir'))
train$Title[bool] = 'other'
# Now we want to see how much people survived in every category:
train %>% dplyr::group_by(Title)  %>% dplyr::filter(Survived == 1) %>%
     summarise(sum = sum(Survived))%>% dplyr::mutate(perc = sum/sum(sum)) # Now we see that 
# the biggest percentage of survived people is people with titles 'Miss' and 'Mrs'

# Next variable that we want to eliminte are SibSp and Parch. We want to convert these
# two variables in one fam_size.
train = train %>% dplyr::mutate(fam_size = SibSp+Parch) %>% select(-c(SibSp, Parch))

# We want to eliminate other varibles as well, that are not so important in our model:
train = train %>% dplyr::select(-c(Name, Ticket, PassengerId))

head(train) # Our train data is ready for the model building but it first have to do the 
# same wiht the test data.
 
                              #### For the test data ####
colSums(is.na(test))
## Age ##
test_num = conv_to_num(test)
imputed = mice(test_num, m=5, maxit = 50, method = 'pmm', seed = 500) 
summary(imputed)
mice::complete(imputed,2) 
test[,c('Age','Fare')] = mice::complete(imputed, 2)[,c('Age','Fare')]
colSums(is.na(test))
## Title ##
test$Title = str_extract(test$Name,' ([A-Za-z]+)[.]')
table(str_extract(test$Name,' ([A-Za-z]+)[.]')) 
bool = str_detect(test$Title, c('Capt|Col|Countess|Don|Dr|Jonkheer|Lady|Major|Mlle|Mme|Rev|Sir|Ms'))
test$Title[bool] = 'other'
##  SibSp and Parch ##
test = test %>% dplyr::mutate(fam_size = SibSp+Parch) %>% select(-c(SibSp, Parch))
test = test %>% dplyr::select(-c(PassengerId, Name, Ticket, Cabin))


                         #### Model Building ####
# Here we will do Cross-Validation on our train data because Kaggle doesnt give any 
# test data for y variable.
index = createDataPartition(train$Survived, p=0.8, times = 1, list=FALSE)
train_train = train[index,]
train_test = train[-index,]
# Here we just try different models for classification:
  ### Logistic Regression ###
mod1 = glm(Survived ~ ., data = train_train, family= 'binomial')
pred1 = ifelse(predict(mod1, newdata = train_test, type='response') > 0.5,1,0) 
Accuracy(pred1,train_test$Survived)
  
  ### KNN ###
mod2 = knn3(Survived ~ ., data =ex_train)
pred2= ifelse(predict(mod2, newdata = ex_test)[,1]- predict(mod2, newdata = ex_test)[,2]>=0,0,1)
Accuracy(pred2,train_test$Survived)

  ### Decision Tree ###
mod3 = rpart(Survived ~ ., data = train_train, method="class") 
printcp(mod3) # Here we choose complexity parameter with the smallest xerror.
plotcp(mod3) # we can see from the graph how chages xerror by changing of cp(complexity parameter).
mod3 = prune(mod3, cp=mod3$cptable[which.min(mod3$cptable[,"xerror"]),"CP"])
pred3 = ifelse(predict(mod3, newdata = train_test)[,1]-predict(mod3, newdata = train_test)[,2]>= 0,0,1)
Accuracy(pred3, train_test$Survived)

  
  
### Extra Trees Classifier ###
ex_train = train_train
ex_train$Sex = as.numeric(ex_train$Sex)
ex_train$Embarked = as.numeric(ex_train$Embarked)
ex_train$Title = as.factor(ex_train$Title)
ex_train$Title = as.numeric(ex_train$Title)
ex_test = train_test[,-1]
ex_test$Sex = as.numeric(ex_test$Sex)
ex_test$Embarked = as.numeric(ex_test$Embarked)
ex_test$Title = as.factor(ex_test$Title)
ex_test$Title = as.numeric(ex_test$Title)
mod4 = extraTrees(x=ex_train[,-1], y=ex_train$Survived)
pred4 = ifelse(predict(mod4, newdata = ex_test)>0.5, 1,0)
Accuracy(pred4, train_test$Survived)

 ### Random Forest Classifier ###

mod5 = randomForest(x=ex_train[,-1],y=as.factor(ex_train[,1]), ntree=500)
pred5 = predict(mod5, newdata = ex_test)
Accuracy(pred5, train_test$Survived)

  ### Naive Bayes ###
mod6 = naiveBayes(Survived ~ ., data = train_train)
pred6 = ifelse(predict(mod6, newdata = train_test, type='raw')[,1]-predict(mod6, newdata = train_test, type='raw')[,2]>=0, 0,1)
Accuracy(pred6, train_test$Survived)
 
   ### SVM  ###
mod7 = svm(Survived ~ ., data = ex_train)
pred7 = ifelse(predict(mod7, newdata = ex_test)>0.5,1,0)
Accuracy(pred7, train_test$Survived)


 ### Ada boost ###
mod8 = gbm(Survived ~ ., data = ex_train, distribution = 'adaboost' ,n.trees = 71)
best_iter =  gbm.perf(mod8)
pred8 = ifelse(predict(mod8, newdata = ex_test, n.trees = 71,type='response')>0.5,1,0)
Accuracy(pred8, train_test$Survived)

 ### XGboost ###
mod9 = xgboost(data=as.matrix(ex_train[,-1]) ,label = as.matrix(ex_train[,1]), max.depth = 2, eta = 1, nthread = 2, nrounds = 10, objective = "binary:logistic")
pred9 = ifelse(predict(mod9, newdata = as.matrix(ex_test))>0.5,1,0)
Accuracy(pred9, train_test$Survived)

 ### Artificial Neural Network ###
# At first we have to Scale our Data:
tr_tr_sc = ex_train
tr_ts_sc = ex_test
tr_tr_sc[c('Age','Fare')] = scale(tr_tr_sc[c('Age','Fare')])
tr_ts_sc[c('Age','Fare')] = scale(tr_ts_sc[c('Age','Fare')])
mod10 =  neuralnet(Survived ~ ., data = tr_tr_sc, hidden = 5)
pred10 = ifelse(compute(mod10, tr_ts_sc)$net.result>0.5,1,0)
Accuracy(pred10, train_test$Survived)

# Now we want to do a graph to see which model was the best for this train dataset:
acc = data.frame(c('Logistic', 'KNN','Decision Tree','Extra Trees Classifier', 'Random Forest','Naive Bayes','SVM','adaBoost', 'XGboost', 'NN'),c(0.8314607,0.7191011,0.8033708,0.8539326,0.8651685,0.8426966, 0.8089888,0.8314607,0.8539326, 0.8595506))
colnames(acc) = c('method', 'value')
acc %>% ggplot(aes(x=reorder(method, value),y= value)) + geom_col()+
  theme(axis.text.x = element_text(angle = 90)) + coord_flip()
# As we can see from the graph that Random Forest has the best performance.
# And Artificial Neural Network is on the second place. But they have not so big difference
# in accuracy.