* Cross tab of actual versus predicted sentiment from text rule builder*;
proc freq data=&EM_IMPORT_SCORE;
Tables Sentiment_Original*EM_CLASSIFICATION;
Run;