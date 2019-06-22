
libname ia 'C:\Users\Steven\Documents\Classes\Fall 2018
		    \Intro to SAS Program - STAT 3094\Final Project - GPlot SAS';

PROC IMPORT OUT= ia.movie_data 
            DATAFILE= "C:\Users\Steven\Documents\Classes\Fall 2018\Intro
 to SAS Program - STAT 3094\Final Project - GPlot SAS\Rotten Tomatos & IMDB.csv" 
            DBMS=CSV REPLACE ;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/* Data management */
data ia.movie;
	set ia.movie_data;

	critics_score = critics_score/10;
	audience_score = audience_score/10;

	rename critics_score = critic_rating
		   audience_score = audience_rating
		   critics_rating = tomato_meter ;

	if critics_score = "." then delete;

	keep critics_score audience_score critics_rating imdb_rating;
run;

/* Average of Ratings */
proc sort data=ia.movie;
	by tomato_meter;
run;
proc summary data=ia.movie print maxdec=2;
	var critic_rating audience_rating imdb_rating;
	by tomato_meter;
run;

/* Scatter plot: critcs vs. audience ratings* by tomato_rating*/

title1 'Rotten Tomatoes Ratings: Scatter Plot';
title2 'Critic vs. Audience Rotten Tomatoes Ratings by Tomatometer';

axis1 label=('Audience Rating');
axis2 label=('Critic Rating') ;
axis3 label=('IMDB Rating') order=(0 to 10 by 1) ;
	
symbol1 value=square color=green;
symbol2 value=star color=blue;
symbol3 value=dot color=red ;
symbol4 value=plus color=grey;

legend1 frame label=("Tomato Meter") repeat=1;

proc gplot data=ia.movie;
	plot critic_rating*audience_rating = tomato_meter /
			haxis=axis1 vaxis=axis2 legend=legend1;
	plot2 imdb_rating*audience_rating /
			vaxis=axis3;
run;

/* Bubble Plot: Critic vs. audience rating by runtime for Certified Fresh*/

title1 'Rotten Tomatoes Ratings: Bubble Plot';
title2 'Critics vs. Audience Rotten Tomatoes Ratings by IMDB Ratings';
proc gplot data=ia.movie;
	where tomato_meter = "Certified Fresh";

	bubble critic_rating*audience_rating = imdb_rating /
			haxis=axis1 vaxis=axis2;
run;

