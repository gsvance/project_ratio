#!/usr/bin/env python3
# main.py
# The top-level executable code for my DSP production chains project


################################
# All Includes for the Project #
################################

# General utilities
from rational_utilities import *
from user_questions import *

# Types for representing DSP game concepts
from rates import *
from facilities import *
from products import *
from recipes import *
from proliferators import *

# DataBase code for loading data and making queries
from databases import *
from abbreviations import *
from recipe_readers import *
from data_loaders import *

# Factories and algorithms for manipulating them based on user input
from factories import *
from algorithms import *


##################################
# Important Subroutines for Main #
##################################

def create_database() -> DataBase:
    db = DataBase()

    print()
    load_database(db)
    db.make_tables()

    return db


#####################################
# Main Function Declared and Called #
#####################################

def main() -> None:
    db = create_database()

    while True:
        factory = generate_factory(db)
        if factory is None:
            break
        print("\n")
        print(str(factory))
        print()
        input()

    return


if __name__ == "__main__":
    main()
