library('ggpubr')
stringsAsFactors=FALSE
library(stringr)
library(gridBase)
library(gridGraphics)
library(optparse)
library(forcats) ### for fct_reorder()

################################ File paths and reading data for making figure ###################################################################

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git")) 

Telomerase_PolyaCounts = file.path(root_dir, "analyses", "telomerase-activity-prediction",
                 "results", "TelomeraseScores_PTBAPolya_counts.txt")   ### Variable representing Telomerase activity-prediction for Polya_counts
				 
Telomerase_StdCounts = file.path(root_dir, "analyses", "telomerase-activity-prediction",
                 "results", "TelomeraseScores_PTBAStranded_counts.txt")  ### Variable representing Telomerase activity-prediction for Stranded_counts
				 
Telomerase_PolyaFpkm = file.path(root_dir, "analyses", "telomerase-activity-prediction",
                 "results", "TelomeraseScores_PTBAPolya_FPKM.txt")      ### Variable representing Telomerase activity-prediction for PolyA_FPKM data
				 
Telomerase_StdFpkm = file.path(root_dir, "analyses", "telomerase-activity-prediction",
                 "results", "TelomeraseScores_PTBAStranded_FPKM.txt")   ### Variable representing Telomerase activity-prediction for Stranded_FPKM data				 
				 
	

Histologies = file.path(root_dir, "data", "pbta-histologies.tsv")   ### Variable representing clinical data 



palette_dir <- file.path(root_dir, "figures", "palettes")
histology_palette <- readr::read_tsv(file.path(palette_dir,"histology_color_palette.tsv"))				  ### reading in histologies color from the define file 
colnames(histology_palette)[1]='short_histology'
histology_palette = data.frame(histology_palette)
hex_codes = histology_palette$hex_codes
names(hex_codes)= histology_palette$short_histology



# Declare output directory
output_dir <- file.path(root_dir, "figures", "pngs")
telomerase_png <- file.path(output_dir, "Telomerase_Activities.png")
supplementary_telomerase_png <- file.path(output_dir, "SuppTelomerase_Activities.png")



PTBA_Histology = read.table(Histologies,sep='\t',head=T)    ## Reading the clinical data
colnames(PTBA_Histology)[colnames(PTBA_Histology)=="Kids_First_Biospecimen_ID"]='SampleID'   ## Renaming "Kids_First_Biospecimen_ID" as SampleID for comparison purpose

TMScores1 = read.table(Telomerase_StdFpkm,sep='\t',head=T)  ## Reading Stranded FPKM telomerase scores
colnames(TMScores1)[colnames(TMScores1)=="NormEXTENDScores"]='NormEXTENDScores_Stranded_FPKM'

PTBA_GE_Standard_Histology = merge(PTBA_Histology,TMScores1,by='SampleID')   ### Merging Clinical data with the Telomerase scores


TMScores2 = read.table(Telomerase_PolyaFpkm,sep='\t',head=T)
colnames(TMScores2)[colnames(TMScores2)=="NormEXTENDScores"]='NormEXTENDScores_PolyA_FPKM'


TMScores3 = read.table(Telomerase_StdCounts,sep='\t',head=T)
colnames(TMScores3)[colnames(TMScores3)=="NormEXTENDScores"]='NormEXTENDScores_StrandedCounts'

TMScores4 = read.table(Telomerase_PolyaCounts,sep='\t',head=T)
colnames(TMScores4)[colnames(TMScores4)=="NormEXTENDScores"]='NormEXTENDScores_PolyACounts'

PBTA_PolyA_TMScores = merge(TMScores2,TMScores4,by='SampleID')
PBTA_Stranded_TMScores = merge(TMScores1,TMScores3,by='SampleID')

########################################## Figure A and B dataframe compilation #########################################################

Stranded_Histology = PTBA_GE_Standard_Histology
Stranded_Histology = Stranded_Histology[-which(Stranded_Histology$short_histology == "Other"),]   ### Removing the tumors with catagory labelled as "Others"
Frequency = data.frame(table(Stranded_Histology$short_histology))  ### Counting the number of cases for all histologies to avoid less number further
colnames(Frequency)=c('Variables','Freq')
Frequency = Frequency[which(Frequency$Freq == 1),]
Stranded_Histology = Stranded_Histology[-which(Stranded_Histology$short_histology %in% Frequency$Variables),]     ### Removing the tumors with only one case in histologies 

Stranded_Histology$short_histology[Stranded_Histology$short_histology == "CNS ganglioneuroblastoma"]= "CNS neuroblastoma"    #### Short hist color data has missing CNS ganglioneuroblastoma therefore renaming it
Stranded_Histology$short_histology[Stranded_Histology$short_histology == "CNS Embryonal tumor"] = "Embryonal Tumor"         #### Short hist color data has missing CNS Embryonal tumor therefore renaming it


########################################## Figure C data compilation #########################################################


Medulloblastoma_His = PTBA_GE_Standard_Histology[which(PTBA_GE_Standard_Histology$short_histology == "Medulloblastoma"),]   ### Select tumors with catagory labelled as "Medulloblastoma"

stat.test <- data.frame(compare_means(
  NormEXTENDScores_Stranded_FPKM ~ molecular_subtype, data = Medulloblastoma_His,
  method = "t.test"
)) 

combinations = nrow(stat.test)

statistics = stat.test%>%
  mutate(y.position = seq(1,by=0.04,length.out=combinations))


#########################################  Saving Figure in PNG format 


## Figure for main text: Boxplots 
png(telomerase_png,width = 5, height = 6, units = "in", res = 1200)

theme_set(theme_classic() +
          theme(plot.title = element_text(size=10, face="bold"),axis.text.x=element_text(angle=40,size=6,vjust=1,hjust=1),axis.text.y=element_text(size=7), axis.title.x = element_text(size=0), axis.title.y = element_text(size=8),
          legend.position = "none",
          legend.key.size= unit(0.3,"cm"),
          legend.key.width = unit(0.3,"cm"),
          legend.title = element_text(size=7),
          legend.text =element_text(size=6)
        )
)



P1 = ggplot(Stranded_Histology, aes(x=fct_reorder(short_histology,NormEXTENDScores_Stranded_FPKM,.desc =TRUE),y=NormEXTENDScores_Stranded_FPKM))+geom_boxplot(size=0.2,notch=FALSE,outlier.size = 0,outlier.shape=NA,aes(color=short_histology,fill=short_histology),alpha=0.4)+ geom_jitter(shape=16, cex=0.1,aes(color=short_histology))
P1 = P1+scale_fill_manual(values = hex_codes)
P1 = P1+scale_color_manual(values = hex_codes)



P2 = ggplot(Stranded_Histology, aes(x=fct_reorder(broad_histology,NormEXTENDScores_Stranded_FPKM,.desc =TRUE),y=NormEXTENDScores_Stranded_FPKM))+geom_boxplot(size=0.2,notch=FALSE,outlier.size = 0,outlier.shape=NA,color="black",fill="#808080",alpha=0.4)+ geom_jitter(shape=16, cex=0.1,color="black")


P3 = ggplot(Medulloblastoma_His, aes(x=fct_reorder(molecular_subtype,NormEXTENDScores_Stranded_FPKM,.desc =TRUE),y=NormEXTENDScores_Stranded_FPKM))+geom_boxplot(size=0.2,notch=FALSE,outlier.size = 0,outlier.shape=NA,color="black",fill="#808080",alpha=0.4)+ geom_jitter(shape=16, width = 0.1,size=0.2,color="black")+stat_pvalue_manual(
    data = statistics, label = "p.adj",size=1.7,
    xmin = "group1", xmax = "group2",tip.length = 0.003,
    y.position = "y.position"
    )

grid.newpage()
# Create layout : nrow = 2, ncol =2
pushViewport(viewport(layout = grid.layout(nrow = 6, ncol =3)))
# A helper function to define a region on the layout
define_region <- function(row, col){
  viewport(layout.pos.row = row, layout.pos.col = col)
} 



print(ggpar(P1,font.xtickslab =c(5,"black"),font.ytickslab =6,font.x = 6,font.y=6,ylab="EXTEND Scores",xlab = "Tumor Short Histology",title="A",font.title=7),vp = define_region(row = 1:3, col = 1:3))
print(ggpar(P2,font.xtickslab =c(5,"black"),font.ytickslab =6,font.x = 6,font.y=6,ylab="EXTEND Scores",xlab = "Tumor Broad Histology",title="B",font.title=7),vp = define_region(row = 4:6, col = 1:2))
print(ggpar(P3,font.xtickslab =c(5,"black"),font.ytickslab =6,font.x = 6,font.y=6,font.legend=6,xlab="Medulloblastoma Subgroups",ylab="EXTEND Scores",title="C",font.title=7),vp = define_region(row = 4:5, col = 3))

dev.off()



## Figure for SI: scatterplots
png(supplementary_telomerase_png,width = 4, height = 2, units = "in", res = 1200)

theme_set(theme_classic() +
          theme(plot.title = element_text(size=10, face="bold"),axis.text.x=element_text(angle=25,size=6,vjust=1,hjust=1),axis.text.y=element_text(size=7), axis.title.x = element_text(size=0), axis.title.y = element_text(size=8),
          legend.position = "none",
          legend.key.size= unit(0.3,"cm"),
          legend.key.width = unit(0.3,"cm"),
          legend.title = element_text(size=7),
          legend.text =element_text(size=6)
        )
)


P1 = ggscatter(PBTA_PolyA_TMScores, x = "NormEXTENDScores_PolyACounts", y = "NormEXTENDScores_PolyA_FPKM",color = "red",size = 0.2,
add = "reg.line",  # Add regressin line
add.params = list(color = "black", fill = "grey",size=0.5), # Customize reg. line
conf.int = TRUE # Add confidence interval
)+ stat_cor(method = "spearman",size=2)

		   
P2 = ggscatter(PBTA_Stranded_TMScores, x = "NormEXTENDScores_StrandedCounts", y = "NormEXTENDScores_Stranded_FPKM",color = "red",size = 0.2,
add = "reg.line",  # Add regressin line
add.params = list(color = "black", fill = "grey",size=0.5), # Customize reg. line
conf.int = TRUE # Add confidence interval
)+ stat_cor(method = "spearman",size=2)



grid.newpage()
# Create layout : nrow = 2, ncol =2
pushViewport(viewport(layout = grid.layout(nrow = 1, ncol =2)))
# A helper function to define a region on the layout
define_region <- function(row, col){
  viewport(layout.pos.row = row, layout.pos.col = col)
} 



print(ggpar(P1,font.xtickslab =4,font.ytickslab =4,font.x = 4,font.y=4,xlab="PolyA Counts EXTEND Scores",ylab="PolyA FPKM EXTEND Scores",title="A",font.title=7),vp = define_region(row = 1, col = 1))
print(ggpar(P2,font.xtickslab =4,font.ytickslab =4,font.x = 4,font.y=4,xlab="Stranded Counts EXTEND Scores ",ylab="Stranded FPKM EXTEND Scores",title="B",font.title=7),vp = define_region(row = 1, col = 2))

dev.off()



