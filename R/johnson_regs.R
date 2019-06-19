#setwd('~/Dropbox/pkg.data/curb_appeal/Data/')
johnson_regs <- function(runRegs=FALSE){
  if(runRegs==TRUE){
    library(data.table)
    dt <- as.data.table(readstata13::read.dta13(file = '~/Dropbox/pkg.data/curb_appeal/Data/curb_sriram_score_bin2.dta'))
    dt <- dt[, score_own:=score_own-1]
    dt <- dt[, score_across:=score_across-1]
    
    saveRDS(dt, file='~/Dropbox/pkg.data/curb_appeal/Data/johnson.rds')
    
    dt <- readRDS('~/Dropbox/pkg.data/curb_appeal/Data/johnson.rds')
    sd_score_across <- sd(dt$score_across)
    dt <- dt[, score_own_sq := score_own^2]
    dt <- dt[, score_across_sq := score_across^2]
    
    dt <- dt[!is.na(score_across)&!is.na(score_own)]
    dt <- dt[, own_nbhd := mean(score_own), by=nbhd_1]
    
    dt <- dt[, diff_nbhd_own := (score_own - own_nbhd)^2]
    dt <- dt[, diff_nbhd_across := (score_across - own_nbhd)^2]
    dt <- dt[, ind_own_across := ifelse(score_own > score_across, 1, 0)]
    dt <- dt[, ind_own_across_1sd := ifelse(score_own > score_across+sd_score_across, 1, 0)]
    dt <- dt[, ind_own_across_0_1sd := ifelse(score_own > score_across & ind_own_across_1sd < 1 , 1, 0)]
    dt <- dt[, ind_own_across_2sd := ifelse(score_own > score_across+2*sd_score_across, 1, 0)]
    dt <- dt[, ind_own_across_1sd_2sd := ifelse(ind_own_across_1sd > 0 & ind_own_across_2sd < 1 , 1, 0)]
    
    dt <- dt[, ind_own_across_1sd_neg := ifelse(score_own < score_across-sd_score_across, 1, 0)]
    dt <- dt[, ind_own_across_0_1sd_neg := ifelse(score_own < score_across & ind_own_across_1sd_neg < 1 , 1, 0)]
    
    dt <- dt[, ind_own_across_2sd_neg := ifelse(score_own < score_across-2*sd_score_across, 1, 0)]
    dt <- dt[, ind_own_across_1sd_2sd_neg := ifelse(ind_own_across_1sd_neg > 0 & ind_own_across_2sd_neg < 1 , 1, 0)]
    
    dt <- dt[, score_diff := score_own - score_across]
    dt <- dt[, score_diff_0_1:=0]
    dt <- dt[score_diff > 0 & score_diff < 1, score_diff_0_1 := 1]
    dt <- dt[, score_diff_1_2:=0]
    dt <- dt[score_diff > 1 & score_diff < 2, score_diff_1_2 := 1]
    dt <- dt[, score_diff_2_3:=0]
    dt <- dt[score_diff > 2 & score_diff < 3, score_diff_2_3 := 1]
    
    dt <- dt[, ind_own_across_0_1 := ifelse(score_own - score_across, 1, 0)]
    dt <- dt[, ind_own_across_1_2:= ifelse(score_own > score_across & ind_own_across_1sd < 1 , 1, 0)]
    dt <- dt[, ind_own_across_2_3 := ifelse(score_own > score_across+2*sd_score_across, 1, 0)]
    dt <- dt[, ind_own_across_1sd_2sd := ifelse(ind_own_across_1sd > 0 & ind_own_across_2sd < 1 , 1, 0)]
    
    
    dt <- dt[, ind_nbhd_own := ifelse(score_own > own_nbhd, 1, 0)]
    dt <- dt[, int_nbhd_own := ind_nbhd_own * diff_nbhd_own]
    dt <- dt[, mean_score_own := mean(score_own), by=nbhd_1]
    dt <- dt[, mean_score_across := mean(score_across), by = nbhd_1]
    dt <- dt[, mean_score := ((score_own + score_across)/2)]
    dt <- dt[, mean_score_nbhd_1 := mean(mean_score), by= nbhd_1]
    dt <- dt[, mean_own_score_nbhd_1 := mean(score_own), by=nbhd_1]
    dt <- dt[, mean_across_score_nbhd_1 := mean(score_across), by=nbhd_1]
    dt <- dt[, diff_score_own_nbhd_1 := (score_own-mean_score_own)]
    dt <- dt[, int_score := (score_own-mean_own_score_nbhd_1)*(score_across-mean_across_score_nbhd_1)]
    dt <- dt[, int_own_score:=(score_own-mean_own_score_nbhd_1)*(score_across-mean_own_score_nbhd_1)]
    dt <- dt[, int_across_score:=(score_own-mean_across_score_nbhd_1)*(score_across-mean_across_score_nbhd_1)]
    
    dt <- dt[, int_score_above := int_score * ind_own_across]
    dt <- dt[, score_own_diff := score_own - mean_own_score_nbhd_1]
    dt <- dt[, score_across_diff := score_across - mean_across_score_nbhd_1]
    # Indicator Variables
    dt <- dt[, ind_own_pos_across_pos:=0]
    dt <- dt[(score_own > mean_own_score_nbhd_1 & score_across > mean_across_score_nbhd_1), ind_own_pos_across_pos := 1]
    
    dt <- dt[, ind_own_pos_across_neg:=0]
    dt <- dt[(score_own > mean_own_score_nbhd_1 & score_across < mean_across_score_nbhd_1), ind_own_pos_across_neg := 1]
    
    dt <- dt[, ind_own_neg_across_pos:=0]
    dt <- dt[(score_own < mean_own_score_nbhd_1 & score_across > mean_across_score_nbhd_1), ind_own_neg_across_pos := 1]
    
    dt <- dt[, ind_own_neg_across_neg:=0]
    dt <- dt[(score_own < mean_own_score_nbhd_1 & score_across < mean_across_score_nbhd_1), ind_own_neg_across_neg := 1]
    
    dt <- dt[, ind_pos_pos := ind_own_pos_across_pos * int_score]
    dt <- dt[, ind_pos_neg := ind_own_pos_across_neg * int_score]
    dt <- dt[, ind_neg_pos := ind_own_neg_across_pos * int_score]
    dt <- dt[, ind_neg_neg := ind_own_neg_across_neg * int_score]
    
    dt <- dt[, ind_pos_pos_gt := ind_pos_pos*ind_own_across]
    dt <- dt[, int_own_across_score := ind_own_across * int_score]
    dt <- dt[, ind_own_gt_nbhd_1 := ifelse(score_own > mean_score_nbhd_1, 1, 0)]
    
    
    dt <- dt[, int_diff_own_across := ind_own_across * (score_own-score_across)]
    
    
    model.a <- lm(log(sale_price) ~  
                    score_own +
                    score_across +
                    score_diff_0_1 +
                    score_diff_1_2 +
                    score_diff_2_3 + 
                    # ind_own_across_0_1sd_neg +
                    #  ind_own_across_0_1sd +
                    #  ind_own_across_1sd + 
                    #        score_own_sq + 
                    #       score_across_sq + 
                    #   
                    #              ind_own_across_2sd + 
                    #        ind_own_across_1sd_neg + 
                    #             ind_own_across_2sd_neg + 
                    #   #  ind_own_across + 
                    
                  #     int_score + 
                  
                  #    mean_score_nbhd_1 +
                  #  ind_own_gt_nbhd_1 + 
                  #      ind_own_pos_across_pos +
                  #      ind_own_pos_across_neg +
                  #     ind_own_neg_across_pos +
                  #      ind_own_neg_across_neg +
                  #      ind_pos_pos +
                  #      ind_pos_neg +
                  #      ind_neg_pos +
                  #      ind_neg_neg +
                  #         mean_across_score_nbhd_1 +
                  #         ind_own_pos_across_pos + 
                  #         ind_own_pos_across_neg +
                  #         ind_own_neg_across_neg + 
                  #          ind_pos_pos + 
                  #          ind_pos_neg + 
                  #          ind_neg_pos +
                  #          ind_neg_neg +
                  #mean_score_own +
                  #mean_score_across + 
                  #mean_score_nbhd_1 + 
                  # mean_own_score_nbhd_1 +
                  #int_score_above +
                  #mean_score_nbhd_1 +
                  #mean_score_across + 
                  #int_own_score +
                  #                int_across_score +
                  lsqft + as.factor(bed_rms) + as.factor(baths) + age + story +
                    as.factor(sale_year) + 
                    as.factor(nbhd_1) + 
                    #as.factor(style) +
                    llotsize #+ ,
                  , data=dt)
    return(summary(model.a))
  } else {
    return('Please Run Regs')
  }
} 


