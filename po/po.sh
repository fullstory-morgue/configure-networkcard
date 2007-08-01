#!/bin/bash

{
bash --dump-po-strings ./netcardconfig

} | msguniq > po/messages.pot
