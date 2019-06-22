setwd('C:/Users/Steven/Documents/Classes/Fall 2018/Intro to Data Analytic - STAT 3654/Movie Project')

movie5000 <- read.csv(file='IMDB 5000.csv', header=T, sep=',')
rotten_imdb <- read.csv(file='Rotten Tomatos & IMDB - movies.csv', header=T, sep=',')

library(ggplot2)
library(MASS)
library(GGally)
library(dplyr)
library(pander)
library(leaps)
library(bestglm)
library("ResourceSelection")
# -----bestglm model----
best.RI <- rotten_imdb[, c('genre', 'runtime', 'mpaa_rating', 'thtr_rel_year', 'imdb_rating', 'best_pic_nom',
                           'title_type','director', 'actor1', 'best_pic_win')] #removed director and actor1 to make bestglm work
best.RI <- best.RI %>% mutate(best_pic_nom = ifelse(best_pic_nom == "no", 0, 1))

best.RI <- best.RI %>% mutate(best_pic_win = ifelse(best_pic_win == "no", 0, 1))

best.RI.glm <- within(best.RI, {
  y <- best_pic_win
  best_pic_win <- NULL
})

best_model <- bestglm(best.RI , family=binomial, IC='AIC')
summary(best_model) %>% pander() # Null model vs. saturated
best_model$BestModel %>% pander() # model with features
best_model$BestModels
best_model$Subsets 

best.RI.pred <- predict(best_model$BestModel, type='response')

best.RI.pred <- cbind(RI, fitted=fitted.win, fitted_full=fitted.win.full)

ggplot(best.RI, aes(x=imdb_rating, y=best_pic_win, color=best_pic_nom)) + geom_point()
# ---IMDB Scores---

#IMDB5000
summary(movie5000['duration'])

# -----------Rotten Tomatoes vs. IMDB----------------------------------------------------------------


# change best_pic_nom/win to 1 and 0
RI <- rotten_imdb[, c('genre', 'runtime', 'mpaa_rating', 'thtr_rel_year', 'imdb_rating', 'best_pic_nom',
                       'director', 'actor1', 'title_type', 'best_pic_win')]
RI <- na.omit(RI)

RI <- RI %>% mutate(best_pic_nom = ifelse(best_pic_nom == "no", 0, 1))
RI$best_pic_nom

RI <- RI %>% mutate(best_pic_win = ifelse(best_pic_win == "no", 0, 1))
RI$best_pic_win
#levels(RI$best_pic_win) <- c('yes' = 1, 'no'=0)

cor(RI$imdb_rating, RI$best_pic_win)

ggplot(RI, aes(x=imdb_rating, y=best_pic_nom))+ geom_point() + geom_smooth(method='lm')

# -----Rotten  IMDB: best_pic_nom--------
cor(RI$imdb_rating, RI$best_pic_nom)

fit.null <- glm(best_pic_nom ~ 1, RI, family='binomial')
fit.full <- glm(best_pic_nom ~  genre+runtime+mpaa_rating+imdb_rating+title_type, RI , family='binomial')

fit.best <- stepAIC(fit.null, direction='both', scope = list(upper = fit.full, lower = fit.null ) )
summary(fit.best)
formula(fit.best)

#------------------------------ROtten IMDB: best_pic_win-------------
cor(RI$imdb_rating, RI$best_pic_win)

fit.null2 <- glm(best_pic_win ~ 1, RI, family='binomial')
fit.full2 <- glm(best_pic_win ~  title_type+genre+runtime+mpaa_rating+imdb_rating+thtr_rel_year+director+actor1
                 , RI , family='binomial')

fit.best2 <- stepAIC(fit.null2, direction='both', scope = list(upper = fit.full2, lower = fit.null2 ))
summary(fit.best2)
fit.best2 %>% summary() %>% pander()
formula(fit.best2) 

#Hosmer-Lemeshow Goodness of fit Test
hoslem.test(RI$best_pic_win, fitted(fit.best2)) %>% pander()

#Best_pic vs. imdb and runtime





# -----plot regression model on: plot------

#~~~~~Using slighty More data: Rot dataset~~~~~~~
# Set up dataset
Rot <- rotten_imdb
Rot <- head(Rot, -2)
Rot <- Rot[-334,]
Rot <- Rot %>% mutate(decade = ifelse(thtr_rel_year >= 1970 & thtr_rel_year <1980, '1970', 
                                    ifelse(thtr_rel_year >=1980 & thtr_rel_year <1990, '1980',
                                           ifelse(thtr_rel_year >=1990 & thtr_rel_year <2000, '1990',
                                                  ifelse(thtr_rel_year >=2000 & thtr_rel_year <2010, '2000',
                                                         ifelse(thtr_rel_year >= 2010, '2010', 'NA')
                                                  )
                                           )
                                    )
) )
Rot <- Rot %>% mutate(best_pic_nom = ifelse(best_pic_nom == "no", 0, 1))
RI$best_pic_nom

Rot <- Rot %>% mutate(best_pic_win = ifelse(best_pic_win == "no", 0, 1))
RI$best_pic_win
# Rot model


Rot.null <- glm(best_pic_win ~ 1, Rot, family='binomial')
Rot.full <- glm(best_pic_win ~  title_type+genre+runtime+mpaa_rating+imdb_rating+thtr_rel_year
                 , Rot , family='binomial')

Rot.best <- stepAIC(Rot.null, direction='both', scope = list(upper = Rot.full, lower = Rot.null ))
summary(Rot.best)

Rot.simp.model <- glm(best_pic_win ~ imdb_rating + decade, data=Rot, family='binomial') # y=imdb + runtime model
Rot.simp.model %>% summary() %>% pander()
hoslem.test(Rot$best_pic_win, fitted(Rot.simp.model)) %>% pander()

Rot.fitted.win <- predict(Rot.simp.model, type='response')
Rot.fitted.win.full <- predict(Rot.best, type='response')
Rot <- cbind(Rot, fitted=Rot.fitted.win, fitted_full=Rot.fitted.win.full)
# Plot Models
ggplot(Rot, aes(x=imdb_rating, y=best_pic_win, color=decade))+ geom_point() + 
  geom_line(data=Rot, aes(x=imdb_rating, y=fitted_full), color='red') +
  geom_line(data=Rot, aes(x=imdb_rating, y=fitted), color='blue')+
  labs(x='IMDB Rating', y='Best Picture Win', title='Best Picture Win vs. IMDB Rating by decade')


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Decade
RI <- RI %>% mutate(decade = ifelse(thtr_rel_year >= 1970 & thtr_rel_year <1980, '1970', 
                    ifelse(thtr_rel_year >=1980 & thtr_rel_year <1990, '1980',
                           ifelse(thtr_rel_year >=1990 & thtr_rel_year <2000, '1990',
                                  ifelse(thtr_rel_year >=2000 & thtr_rel_year <2010, '2000',
                                         ifelse(thtr_rel_year >= 2010, '2010', 'NA')
                                         )
                                  )
                          )
                    ) )


# regression line
simp.model <- glm(best_pic_win ~ imdb_rating + decade, data=RI, family='binomial') # y=imdb + runtime model
simp.model %>% summary() %>% pander()

fitted.win <- predict(simp.model, type='response')
fitted.win.full <- predict(fit.best2, type='response')
RI <- cbind(RI, fitted=fitted.win, fitted_full=fitted.win.full)


# win scatter: x=imdb
ggplot(RI, aes(x=imdb_rating, y=best_pic_win, color=decade))+ geom_point() + 
  geom_line(data=RI, aes(x=imdb_rating, y=fitted_full ), color='red') +
  geom_line(data=RI, aes(x=imdb_rating, y=fitted), color='blue')+
  labs(x='IMDB Rating', y='Best Picture Win', title='Best Picture Win vs. IMDB Rating by runtime')

#win scatter: x=runtime
ggplot(RI, aes(x=runtime, y=best_pic_win, color=imdb_rating))+ geom_point() + 
  geom_line(data=RI, aes(x=imdb_rating, y=fitted), color='blue')+
  scale_color_continuous(low='green', high='red')+
  labs(x='Runtime', y='Best Picture Win', title='Best Picture Win vs. Runtime by IMDB Rating')



ggplotRegression <- function (fit) {
  
  require(ggplot2)
  
  ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) + 
    geom_point() +
    stat_smooth(method = "lm", col = "red") +
    labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
                       "Intercept =",signif(fit$coef[[1]],5 ),
                       " Slope =",signif(fit$coef[[2]], 5),
                       " P =",signif(summary(fit)$coef[2,4], 5)))
}


# ----COrr plot-------

ggpairs(RI[, 2:4])

# ----------------Marketing and performance----------------------

# Another aspect of the IMDB 5000 dataset that we can look into is the amount of 
# facebook likes vs. the performance of the movie. Since the dataset contains the 
# number of facebook likes by lead actors, director, and movie, we can see if there 
# is a trend between how well a movie is marketed on facebook and if the movie receives 
# high or low ratings.

market.full <- movie5000[, c(2, 5:8, 11, 14:16, 20:22, 25:26, 28)]

market <- na.omit(movie5000[, c( 'director_facebook_likes', 'actor_1_facebook_likes', 'actor_2_facebook_likes', 'actor_3_facebook_likes', 
                         'cast_total_facebook_likes', 'facenumber_in_poster', 'movie_facebook_likes', 'imdb_score',
                         'facenumber_in_poster', 'content_rating', 'country', 'language')] 
                  )
market.new <- na.omit(movie5000[, c( 'director_facebook_likes', 'actor_1_facebook_likes', 'actor_2_facebook_likes', 'actor_3_facebook_likes', 
                                     'cast_total_facebook_likes', 'facenumber_in_poster', 'movie_facebook_likes', 'imdb_score',
                                     'facenumber_in_poster')] )

# High vs. low data subset

market$highlow <- ifelse(market$imdb_score >= 5.0, 1, 0)

# Correlation matrix
ggpairs(market.new[, 1:9] ) # ggplot scatter matrix 

#------ Best Model ---- stepAIC
fit.null <- lm(imdb_score ~ 1, market)
fit.full <- lm(imdb_score ~ ., market) #Takes too long

fit.best <- stepAIC(fit.null, direction = "both", scope = list(upper = fit.full, lower = fit.null ) )
summary(fit.best)
formula(fit.best)

# ----------plot--------

market.predict <- cbind(market, predict(fit.best, interval = "confidence"))

ggplot(market.predict, aes(x=movie_facebook_likes, y=imdb_score)) +
  geom_line(aes(movie_facebook_likes, fit), color = "blue") + geom_point() +
  coord_cartesian(ylim = c(0, 10))

ggplotRegression(fit.best)


ggplotRegression <- function (fit) {
  
  require(ggplot2)
  
  ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) + 
    geom_point() +
    stat_smooth(method = "lm", col = "red") +
    labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
                       "Intercept =",signif(fit$coef[[1]],5 ),
                       " Slope =",signif(fit$coef[[2]], 5),
                       " P =",signif(summary(fit)$coef[2,4], 5)))
}


# ------- high low plot -----
market.high <- market[ which(market$highlow == 1),]
market.low <- market[ which(market$highlow == 0),]

ggplot(market.high, aes(x=movie_facebook_likes, y=imdb_score)) + geom_point()

ggplot(market.low, aes(x=movie_facebook_likes, y=imdb_score)) + geom_point()


# Correlation Coef
cor(market$imdb_score, market$movie_facebook_likes)



# Ranking top 50 actors -----------

actors <- as.vector(as.matrix(market.full[,c("actor_1_name", "actor_2_name", "actor_3_name")]))


actors.top50 <- names(sort(table(actors), decreasing = T)[0:50])
actors.top50 <- actors.top50[, which()]
  
actors.top50.movies <- subset(market.full , actor_1_name %in% actors.top50 | actor_2_name %in% actors.top50 | actor_3_name %in% actors.top50) 

# Ranking top 50 directors

