# Trophic data glmm
# Ana Miller-ter Kuile
# February 23, 2022

# this script runs glmm for the trophic (isotope) data for top and intermediate predators



# Load packages -----------------------------------------------------------

package.list <- c("here", "tidyverse", "glmmTMB",
                  "effects", "MuMIn", "DHARMa",
                  "patchwork", "performance")

## Installing them if they aren't already on the computer
new.packages <- package.list[!(package.list %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

## And loading them
for(i in package.list){library(i, character.only = T)}

# Load data ---------------------------------------------------------------

#top preds:
source(here("code", 
            "01_cleaning",
            "top_isotopes.R"))
#df = spider_iso


# Models ------------------------------------------------------------------

#d15 N by productivity level
m1 <- glmmTMB(d15N_c ~ Habitat + (1|Year) + (1|Island),
              data = spider_iso)

summary(m1)
confint(m1)
plot(allEffects(m1))
simulateResiduals(m1, plot = T)
r2_nakagawa(m1)
#d14 C by productivity level
m2 <- glmmTMB(d13C ~ Habitat + (1|Year) + (1|Island),
              data = spider_iso)
confint(m2)
summary(m2)
plot(allEffects(m2))
simulateResiduals(m2, plot = T)
r2_nakagawa(m2)


# Those with DNA only -----------------------------------------------------

dna_isotopes <- DNA_iso %>%
  filter(!is.na(d15N_c)) %>%
  distinct(Island, Extraction.ID, Habitat, d15N_c)

dna_isotopes %>%
  group_by(Island) %>%
  tally()

m3 <- glmmTMB(d15N_c ~ Habitat + (1|Island),
data = dna_isotopes)

confint(m3)
summary(m3)
plot(allEffects(m3))
simulateResiduals(m3, plot = T)


# Isotopes and body size --------------------------------------------------

m_length <- glmmTMB(d15N_c ~ Length_mm + (1|Year) + (1|Island), 
                  data = spider_iso)

m_mass <- glmmTMB(d15N_c ~ Mass_g + (1|Year) + (1|Island), 
                  data = spider_iso)

summary(m_length)
plot(allEffects(m_length))
confint(m_length)

summary(m_mass)
confint(m_mass)

# Visualizations ----------------------------------------------------------

d15 <- ggplot(spider_iso, aes(x = Habitat, y = d15N_c, fill = Habitat)) +
  geom_boxplot(size =1, alpha = 0.6) +
  geom_point(aes(color = Habitat), 
             position=position_jitterdodge()) +
  theme_bw() +  
  labs(y = expression({delta}^15*N~ ('\u2030')), 
       x = "Habitat",
       fill = "Habitat") +
  scale_fill_manual(values = c("#bf812d",
                               "#80cdc1")) +
  scale_color_manual(values = c("#bf812d",
                                "#80cdc1")) +
  theme(legend.position = "none",
        axis.text.x = element_blank(),
        axis.title.x = element_blank()) 

d13 <- ggplot(spider_iso, aes(x = Habitat, y = d13C, fill = Habitat)) +
  geom_boxplot(size =1, alpha = 0.6) +
  geom_point(aes(color = Habitat), 
             position=position_jitterdodge()) +
  theme_bw() +  
  labs(y = expression({delta}^13*C~ ('\u2030')), 
       x = "Habitat",
       fill = "Habitat") +
  scale_fill_manual(values = c("#bf812d",
                               "#80cdc1")) +
  scale_color_manual(values = c("#bf812d",
                                "#80cdc1")) +
  theme(legend.position = "none") 


(iso_graphs <- d15/d13)

ggsave(plot = iso_graphs,
       filename = 'iso_graphs.png',
       path = here("pictures", "R"),
       width = 4, height = 5,
       units = "in")
