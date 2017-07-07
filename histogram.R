args <- commandArgs(TRUE)

input <- args[1]	#"/home/bertrandd/PROJECT_LINK/OPERA_LG/META_GENOMIC_HYBRID_ASSEMBLY/DATA/MOCK_20/NANOPORE/LIBRARY/N032/N032_2D/N032.size"
title <- args[2]	#"N032 2D Nanopore"
output <- args[3]	#"/home/bertrandd/PROJECT_LINK/OPERA_LG/META_GENOMIC_HYBRID_ASSEMBLY/ANALYSIS/PLOT/MOCK_20/NANOPORE/LIBRARY/N032/N032_2D/N032.hist.pdf"
max_length <- args[4]	# max read length
break_steps <- as.numeric(as.character(args[5]))	# break steps
xlimit <- as.numeric(as.character(args[6]))        # right limit of histogram

data=read.table(input)

library(plyr)
round_any(as.numeric(as.character(max_length)), 500, f = ceiling)


Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

Mode(data[,ncol(data)])

pdf(file=output,
                    )

par(mar=c(5.1,5.5,4.1,2.1))
hist(data[,ncol(data)]/1000,yaxt="n",main=title,cex.lab=2.5,xlab="Read length (kb)",ylab="Frequency",col="royalblue",cex.axis=2.5,xlim=c(0,xlimit/1000),xaxt="n",freq=FALSE,breaks=seq(0,round_any(as.numeric(as.character(max_length))/1000, break_steps, f = ceiling),by=break_steps))
#axis(side=1, at=axTicks(1),cex.axis=1.9, 
#     labels=formatC(axTicks(1), format="d", big.mark=','))

axis(1,cex.axis=1.9)
axis(2,cex.axis=1.9)
abline(v=Mode(data[,ncol(data)])/1000,col="red",lwd=2)
abline(v=Mode(data[,ncol(data)])*2/1000,col="green",lwd=2)
#abline(v=383*3,col="purple",lwd=2)
dev.off()
