#!/bin/sh

# make sure link to active reagent binary exists
if [ ! -L /opt/reagent/Reagent-active ]; then
  ln -sv /opt/reagent/reagent-latest /opt/reagent/Reagent-active
fi
