# DNA Dataset Cleaning
# Ana Miller-ter Kuile
# May 5, 2021

# this script takes in and cleans the  DNA dataset, 
# creating an output of DNA data for spiders across 
# islets with islet categories and associated 
# isotope data for those spiders that ahve isotopes
#attached to them

# Load packages and source ------------------------------------------------

package.list <- c("here", "tidyverse")

## Installing them if they aren't already on the computer
new.packages <- package.list[!(package.list %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

## And loading them
for(i in package.list){library(i, character.only = T)}


# Load source data --------------------------------------------------------

#we'll combine DNA and isotope data?
source(here("code", 
            "01_cleaning", 
            "top_isotopes.R"))

# Load DNA Data -----------------------------------------------------------
#DNA interaction data
DNA <- read.csv(here("data", 
                     "DNA", 
                     "all_prey_DNA.csv"))

#metadata associated with these samples, including sample ID
DNA_meta <- read.csv(here("data",
                          "DNA",
                          "Sample_metadata.csv"))


# Tidy DNA Data -----------------------------------------------------------
#filter out just the cane spiders and
# variables of interest, change ID name and make a presence column
# remove all zero interactions
DNA <- DNA %>%
  filter(sample_str == "HEV") %>%
  filter(Order != "Primates") %>%
  filter(ID_level %in% c("Order", "Family", "Genus", "Species")) %>%
  filter(reads > 1) %>%
  dplyr::select(sample, 
                Class, 
                Order,
                reads) %>%
  mutate(sample = str_sub(sample,1,nchar(sample)-1)) %>%
  mutate(Class = case_when(Class == "Entognatha" ~ 'Collembola',
                           TRUE ~ Class)) %>%
  group_by(sample, Class, Order) %>%
  summarise(reads = sum(reads)) %>%
  mutate(presence = 1)

# get only cane spider data and get distinct and consistent
# naming of samples
DNA_meta <- DNA_meta %>%
  filter(ID == "Heteropoda venatoria") %>% #& Year == 2015) %>%
  mutate(Isotope_ID = word(Isotope_ID,2)) %>%
  dplyr::select(Island, Habitat, Isotope_ID, Extraction.ID) %>%
  distinct(Island, Habitat, Isotope_ID, Extraction.ID) %>%
  mutate(category = case_when(Habitat %in% c('PF', 'PG', 'TA') ~ "high",
                              Habitat == "CN" ~ 'low',
                              TRUE ~ NA_character_)) 

#combine DNA data with the isotope data 
DNA_iso <- spider_iso %>%
  dplyr::select(-Habitat) %>%
  filter(Year == 2015) %>%
  full_join(DNA_meta, by = c("Island", c("ID" = "Isotope_ID"))) %>%
  filter(!is.na(Extraction.ID)) %>%
  left_join(DNA, by = c("Extraction.ID" = "sample")) %>%
  #filter(!Island %in% c("Cooper", "North Fighter")) %>%
  filter(Habitat != "TC") %>%
  mutate(category = case_when(Habitat %in% c('PF', 'PG', 'TA') ~ "high",
                              Habitat == "CN" ~ 'low',
                              TRUE ~ NA_character_)) %>%
  filter(!is.na(Order)) %>%
  dplyr::select(-Island_Area, -Island_prod, -prod_level) %>%
  left_join(islands, by = "Island")


# Bar graph visualization DFs ---------------------------------------------


# #get frequency of different kinds of prey by islet populations
# islet_prey <- DNA_iso %>%
#   group_by(Habitat, Class, Order) %>%
#   summarise(Frequency = n())

#get frequency of different kinds of prey by islet populations
islet_prey <- DNA_iso %>%
  group_by(category, Class, Order) %>%
  summarise(Frequency = n())

#get stats
DNA_iso %>%
  distinct(Extraction.ID) %>%
  tally()

DNA_iso %>%
  distinct(Extraction.ID, category) %>%
  group_by(category) %>%
  tally()

DNA_iso %>%
  group_by(Habitat) %>%
  tally()

DNA_iso %>%
  group_by(category) %>%
  tally()


# Community analyses matrices ---------------------------------------------


DNA_matrix <- DNA_iso %>%
  ungroup() %>%
  dplyr::select(Extraction.ID, Order, presence) %>%
  pivot_wider(names_from = Order,
              values_from = presence,
              values_fill = 0) %>%
  column_to_rownames(var = "Extraction.ID")

DNA_metadata <- DNA_iso %>%
  ungroup() %>%
  dplyr::select(Extraction.ID, category, category, Habitat, Island) %>%
  distinct(category, Island, Habitat, Extraction.ID) %>%
  column_to_rownames(var = "Extraction.ID")

