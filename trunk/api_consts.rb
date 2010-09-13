# api_consts.rb --- decaptcher api

# Copyright  (C)  2010  Marcelo Toledo <marcelo@marcelotoledo.com>

# Version: 1.0
# Keywords:
# Author: Marcelo Toledo <marcelo@marcelotoledo.com>
# Maintainer: Marcelo Toledo <marcelo@marcelotoledo.com>
# URL: http:#

# Commentary:



# Code:

# ERROR CODES
CCERR_OK         = 0    # everything went OK
CCERR_GENERAL    = -1   # general internal error
CCERR_STATUS     = -2   # status is not correct
CCERR_NET_ERROR  = -3   # network data transfer error
CCERR_TEXT_SIZE  = -4   # text is not of an appropriate size
CCERR_OVERLOAD   = -5   # server's overloaded
CCERR_BALANCE    = -6   # not enough funds to complete the request
CCERR_TIMEOUT    = -7   # request timed out
CCERR_BAD_PARAMS = -8   # provided parameters are not good for this function
CCERR_UNKNOWN    = -200 # unknown error

# picture processing TIMEOUTS
PTODEFAULT = 0          # default timeout, server-specific
PTOLONG    = 1          # long timeout for picture, server-specfic
PTO30SEC   = 2          # 30 seconds timeout for picture
PTO60SEC   = 3          # 60 seconds timeout for picture
PTO90SEC   = 4          # 90 seconds timeout for picture

# picture processing TYPES
PTUNSPECIFIED = 0       # picture type unspecified
PTASIRRA      = 86      # picture type - ASIRRA

# multi-picture processing specifics
PTASIRRA_PICS_NUM = 12
